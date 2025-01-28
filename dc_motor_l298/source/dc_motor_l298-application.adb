--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with A0B.STM32F401.GPIO.PIOA;
with A0B.STM32F401.GPIO.PIOB;
with A0B.STM32F401.SVD.ADC;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.TIM;
with A0B.STM32F401.TIM_Lines;
with A0B.Time.Clock;
with A0B.Types;

with Console;

package body DC_Motor_L298.Application is

   use type A0B.Types.Unsigned_16;

   ENA_Pin       : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB8;
   IN1_Pin       : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB7;
   IN2_Pin       : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB6;
   Current_Pin   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA0;
   Voltage_A_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA1;
   Voltage_B_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOA.PA2;

   type State_Kind is (Forward, Backward, Stop, Off);

   State : State_Kind := Off;
   Duty  : Integer range 0 .. 100 := 50;

   procedure Set_State (To : State_Kind);

   procedure Set_Duty (To : Integer);

   procedure Initialize_ADC;

   procedure Do_ADC;

   procedure Process_ADC;

   --  Prescale : constant := 2_100;
   --  Prescale : constant := 210;    --  4/210/1000 = 100 Hz
   --  Prescale : constant := 21;     --  4/21/1000 = 1kHz
   Divider  : constant := 2#00#;  --  1
   Prescale : constant := 1;
   --  Cycle    : constant := 2_100;
   Cycle    : constant := 3_360;
   --  1/1/3_360: PWM 25kHz CPU @84MHz (nominal for L298)
   --  1/1/2_100: PWM 40kHz CPU @84MHz (max for L298)

   type Data is record
      Current   : A0B.Types.Unsigned_16;
      Voltage_A : A0B.Types.Unsigned_16;
      Voltage_B : A0B.Types.Unsigned_16;
   end record;

   ADC_Data : array (1 .. 2_000) of Data with Export;
   --  Filtered : array (1 .. 1_000) of A0B.Types.Unsigned_16 with Export;

   ------------
   -- Do_ADC --
   ------------

   procedure Do_ADC is
      use type A0B.Time.Monotonic_Time;
      use A0B.STM32F401.SVD.ADC;

      Start  : constant A0B.Time.Monotonic_Time := A0B.Time.Clock;
      Period : A0B.Time.Time_Span;

   begin
      for J in ADC_Data'Range loop
         ADC1_Periph.SQR3.SQ.Arr (1) := 2#000#;
         ADC1_Periph.CR2.SWSTART := True;

         while not ADC1_Periph.SR.EOC loop
            null;
         end loop;

         ADC_Data (J).Current := ADC1_Periph.DR.DATA;

         ADC1_Periph.SQR3.SQ.Arr (1) := 2#001#;
         ADC1_Periph.CR2.SWSTART := True;

         while not ADC1_Periph.SR.EOC loop
            null;
         end loop;

         ADC_Data (J).Voltage_A := ADC1_Periph.DR.DATA;

         ADC1_Periph.SQR3.SQ.Arr (1) := 2#010#;
         ADC1_Periph.CR2.SWSTART := True;

         while not ADC1_Periph.SR.EOC loop
            null;
         end loop;

         ADC_Data (J).Voltage_B := ADC1_Periph.DR.DATA;

      end loop;

      Period := A0B.Time.Clock - Start;

      Console.Put_Line
        (A0B.Types.Integer_64'Image (A0B.Time.To_Nanoseconds (Period)));
   end Do_ADC;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.TIM10EN := True;

      declare
         Aux : A0B.STM32F401.SVD.TIM.CR1_Register_2 :=
           A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1;

      begin
         Aux.CEN  := False;    --  Counter disabled
         Aux.UDIS := False;    --  UEV enabled
         Aux.URS  := False;
         --  Aux.URS  := True;
         --  --  ??? Only counter overflow generates an UEV if enabled.
         --  Aux.OPM
         Aux.ARPE := True;     --  TIMx_ARR register is buffered
         Aux.CKD  := Divider;
         --  Aux.CKD  := 2#10#;  --  tDTS = 4 × tCK_INT

         A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1 := Aux;
      end;

      --  RCC_Periph.APB2ENR.TIM11EN := True;
      --
      --  declare
      --     Aux : CR1_Register_2 := TIM11_Periph.CR1;
      --
      --  begin
      --     Aux.CEN  := False;  --  Counter disabled
      --     Aux.UDIS := False;  --  UEV enabled.
      --     Aux.URS  := True;
      --     --  Only counter overflow generates an UEV if enabled.
      --     Aux.ARPE := False;  --  TIMx_ARR register is not buffered
      --     --  Aux.CDK  := <>;
      --
      --     TIM11_Periph.CR1 := Aux;
      --  end;

      A0B.STM32F401.SVD.TIM.TIM10_Periph.PSC.PSC := Prescale - 1;  --  65_536 - 1
      --  A0B.STM32F401.SVD.TIM.TIM10_Periph.PSC.PSC := 65_535;  --  65_536 - 1
        --  A0B.Types.Unsigned_16 (Timer_Peripheral_Frequency / Prescaler_Divider);

      declare
         Aux : A0B.STM32F401.SVD.TIM.CCMR1_Output_Register_2 :=
           A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output;

      begin
         Aux.CC1S  := 2#00#;  --  CC1 channel is configured as output.
      --  --  Output Compare 1 fast enable
      --  OC1FE         : Boolean := False;
      --  --  Output Compare 1 preload enable
      --  OC1PE         : Boolean := False;
         Aux.OC1M  := 2#110#;
         --  PWM mode 1 - Channel 1 is active as long as TIMx_CNT < TIMx_CCR1
         --  else inactive.

         A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output := Aux;
      end;

      declare
         Aux : A0B.STM32F401.SVD.TIM.CCER_Register_3 :=
           A0B.STM32F401.SVD.TIM.TIM10_Periph.CCER;

      begin
      --  --  Capture/Compare 1 output enable
      --  CC1E          : Boolean := False;
         Aux.CC1P := False;  --  OC1 active high

         --  --  unspecified
      --  Reserved_2_2  : A0B.Types.SVD.Bit := 16#0#;
      --  --  Capture/Compare 1 output Polarity
      --  CC1NP         : Boolean := False;

         A0B.STM32F401.SVD.TIM.TIM10_Periph.CCER := Aux;
      end;

      --  --  Enable update interrupt
      --
      --  declare
      --     Aux : DIER_Register_3 := TIM11_Periph.DIER;
      --
      --  begin
      --     Aux.CC1IE := False;  --  CC1 interrupt disabled
      --     Aux.UIE   := True;   --  Update interrupt enabled
      --
      --     TIM11_Periph.DIER := Aux;
      --  end;
      --
      --  A0B.ARMv7M.NVIC_Utilities.Clear_Pending
      --    (A0B.STM32F401.TIM1_TRG_COM_TIM11);
      --  A0B.ARMv7M.NVIC_Utilities.Enable_Interrupt
      --    (A0B.STM32F401.TIM1_TRG_COM_TIM11);

      ENA_Pin.Configure_Alternative_Function
        (Line  => A0B.STM32F401.TIM_Lines.TIM10_CH1,
         Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      IN1_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);
      IN2_Pin.Configure_Output
        (Mode  => A0B.STM32F401.GPIO.Push_Pull,
         Speed => A0B.STM32F401.GPIO.Very_High,
         Pull  => A0B.STM32F401.GPIO.Pull_Up);

      A0B.STM32F401.SVD.TIM.TIM10_Periph.ARR.ARR   := Cycle - 1;
      --  A0B.STM32F401.SVD.TIM.TIM10_Periph.CCR1.CCR1 := 512;
      A0B.STM32F401.SVD.TIM.TIM10_Periph.EGR.UG    := True;
      A0B.STM32F401.SVD.TIM.TIM10_Periph.CCER.CC1E := True;
      --  A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1.CEN   := True;

      IN1_Pin.Set (False);
      IN2_Pin.Set (False);

      Initialize_ADC;
   end Initialize;

   --------------------
   -- Initialize_ADC --
   --------------------

   procedure Initialize_ADC is
      use A0B.STM32F401.SVD.ADC;

   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.ADC1EN := True;

      declare
         Aux : CR1_Register := ADC1_Periph.CR1;

      begin
      --  --  Analog watchdog channel select bits
      --  AWDCH          : CR1_AWDCH_Field := 16#0#;
      --  --  Interrupt enable for EOC
      --  EOCIE          : Boolean := False;
      --  --  Analog watchdog interrupt enable
      --  AWDIE          : Boolean := False;
      --  --  Interrupt enable for injected channels
      --  JEOCIE         : Boolean := False;
      --  --  Scan mode
      --  SCAN           : Boolean := False;
      --  --  Enable the watchdog on a single channel in scan mode
      --  AWDSGL         : Boolean := False;
      --  --  Automatic injected group conversion
      --  JAUTO          : Boolean := False;
      --  --  Discontinuous mode on regular channels
      --  DISCEN         : Boolean := False;
      --  --  Discontinuous mode on injected channels
      --  JDISCEN        : Boolean := False;
      --  --  Discontinuous mode channel count
      --  DISCNUM        : CR1_DISCNUM_Field := 16#0#;
      --  --  unspecified
      --  Reserved_16_21 : A0B.Types.SVD.UInt6 := 16#0#;
      --  --  Analog watchdog enable on injected channels
      --  JAWDEN         : Boolean := False;
      --  --  Analog watchdog enable on regular channels
      --  AWDEN          : Boolean := False;
      --  --  Resolution
      --  RES            : CR1_RES_Field := 16#0#;
      --  --  Overrun interrupt enable
      --  OVRIE          : Boolean := False;
      --  --  unspecified
      --  Reserved_27_31 : A0B.Types.SVD.UInt5 := 16#0#;

         Aux.RES := 2#00#;  --  12-bit (15 ADCCLK cycles)

         ADC1_Periph.CR1 := Aux;
      end;

      declare
         Aux : CR2_Register := ADC1_Periph.CR2;

      begin
      --  --  External event select for injected group
      --  JEXTSEL        : CR2_JEXTSEL_Field := 16#0#;
      --  --  External trigger enable for injected channels
      --  JEXTEN         : CR2_JEXTEN_Field := 16#0#;
      --  --  Start conversion of injected channels
      --  JSWSTART       : Boolean := False;
      --  --  unspecified
      --  Reserved_23_23 : A0B.Types.SVD.Bit := 16#0#;
      --  --  External event select for regular group
      --  EXTSEL         : CR2_EXTSEL_Field := 16#0#;
      --  --  External trigger enable for regular channels
      --  EXTEN          : CR2_EXTEN_Field := 16#0#;
      --  --  Start conversion of regular channels
      --  SWSTART        : Boolean := False;
      --  --  unspecified
      --  Reserved_31_31 : A0B.Types.SVD.Bit := 16#0#;

         Aux.ADON  := False;  --  Disable ADC conversion and go to power down mode
         Aux.CONT  := False;  --  Single conversion mode
         Aux.DMA   := False;  --  DMA mode disabled
         Aux.DDS   := False;
         --  No new DMA request is issued after the last transfer (as configured
         --  in the DMA controller)
         Aux.EOCS  := True;
         --  The EOC bit is set at the end of each regular conversion. Overrun
         --  detection is enabled.
         Aux.ALIGN := False;  --  Right alignment
         --  Aux.ALIGN := True;   --  Left alignment

         ADC1_Periph.CR2 := Aux;
      end;

      --  declare
      --     Aux : CR1_Register := ADC1_Periph.CR1;
      --
      --  begin
      --     ADC1_Periph.CR1 := Aux;
      --  end;

      --  declare
      --     Aux : CR1_Register := ADC1_Periph.CR1;
      --
      --  begin
      --     ADC1_Periph.CR1 := Aux;
      --  end;

      declare
         Aux : CCR_Register := ADC_Common_Periph.CCR;

      begin
         Aux.ADCPRE := 2#01#;  --  PCLK2 divided by 4

         ADC_Common_Periph.CCR := Aux;
      end;

      --  ADC1_Periph.SMPR2 := 2#001#;
      ADC1_Periph.CR2.ADON := True;

      Current_Pin.Configure_Analog;
      Voltage_A_Pin.Configure_Analog;
      Voltage_B_Pin.Configure_Analog;
   end Initialize_ADC;

   -----------------
   -- Process_ADC --
   -----------------

   procedure Process_ADC is
      use type A0B.Types.Integer_64;

      Minimum     : A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16'Last;
      Maximum     : A0B.Types.Unsigned_16 := A0B.Types.Unsigned_16'First;
      Average     : A0B.Types.Unsigned_16;
      Accumulator : A0B.Types.Integer_64  := 0;
      --  Samples     : A0B.Types.Integer_64;

      --  procedure Put_Item (Item : A0B.Types.Unsigned_16);
      --
      --  procedure Put_Item (Item : A0B.Types.Unsigned_16) is
      --  begin
      --     Console.Put
      --       (A0B.Types.Unsigned_16'Image (Item)
      --        & A0B.Types.Unsigned_16'Image (Maximum - Item));
      --  end Put_Item;

   begin
      for J in ADC_Data'Range loop
         Minimum     := A0B.Types.Unsigned_16'Min (@, ADC_Data (J).Current);
         Maximum     := A0B.Types.Unsigned_16'Max (@, ADC_Data (J).Current);
         Accumulator := @ + A0B.Types.Integer_64 (ADC_Data (J).Current);
      end loop;

      Average := A0B.Types.Unsigned_16 (Accumulator / ADC_Data'Length);

      Console.Put_Line
        (A0B.Types.Unsigned_16'Image (Minimum)
         & A0B.Types.Unsigned_16'Image (Average)
         & A0B.Types.Unsigned_16'Image (Maximum)
         & "  "
         & A0B.Types.Unsigned_16'Image (Average - Minimum)
         & A0B.Types.Unsigned_16'Image (Maximum - Average)
         & A0B.Types.Unsigned_16'Image (Maximum - Minimum)
        );

      --  for J in 1 .. 100 loop
      --     Put_Item (ADC_Data (J));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 100));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 200));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 300));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 400));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 500));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 600));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 700));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 800));
      --     Console.Put (' ');
      --     Put_Item (ADC_Data (J + 900));
      --     Console.New_Line;
      --     --  Console.Put_Line
      --     --    (A0B.Types.Unsigned_16'Image (ADC_Data (J))
      --     --     & A0B.Types.Unsigned_16'Image (ADC_Data (J + 200))
      --     --     & A0B.Types.Unsigned_16'Image (ADC_Data (J + 400))
      --     --     & A0B.Types.Unsigned_16'Image (ADC_Data (J + 600))
      --     --     & A0B.Types.Unsigned_16'Image (ADC_Data (J + 800)));
      --  end loop;

      Console.New_Line;
      Console.Put_Line ("Current");

      for J in ADC_Data'Range loop
         if (J - 1) mod 25 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (ADC_Data (J).Current));
      end loop;

      Console.New_Line;
      Console.New_Line;
      Console.Put_Line ("Voltage A");

      for J in ADC_Data'Range loop
         if (J - 1) mod 25 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (ADC_Data (J).Voltage_A));
      end loop;

      Console.New_Line;
      Console.New_Line;
      Console.Put_Line ("Voltage B");

      for J in ADC_Data'Range loop
         if (J - 1) mod 25 = 0 then
            Console.New_Line;
         end if;

         Console.Put (A0B.Types.Unsigned_16'Image (ADC_Data (J).Voltage_B));
      end loop;

      Console.New_Line;

      --  for J in ADC_Data'Range loop
      --     if J = ADC_Data'First then
      --        Accumulator := A0B.Types.Integer_64 (ADC_Data (J));
      --        Samples     := 1;
      --
      --     elsif J in 2 .. 8 then
      --        Accumulator := @ + A0B.Types.Integer_64 (ADC_Data (J));
      --        Samples     := @ + 1;
      --
      --     else
      --        Accumulator := @ - A0B.Types.Integer_64 (ADC_Data (J -  Integer (Samples)));
      --        Accumulator := @ + A0B.Types.Integer_64 (ADC_Data (J));
      --     end if;
      --
      --     Filtered (J) := A0B.Types.Unsigned_16 ( Accumulator / Samples);
      --  end loop;
      --
      --  for J in Filtered'Range loop
      --     if J mod 17 = 0 then
      --        Console.New_Line;
      --     end if;
      --
      --     Console.Put (A0B.Types.Unsigned_16'Image (Filtered (J)));
      --  end loop;

      Console.New_Line;

   end Process_ADC;

   ---------
   -- Run --
   ---------

   procedure Run is
      procedure Display_Duty;

      procedure Update_Duty (To : Integer);

      ------------------
      -- Display_Duty --
      ------------------

      procedure Display_Duty is
      begin
         Console.Put_Line ("PWM Duty" & Integer'Image (Duty) & '%');
      end Display_Duty;

      -----------------
      -- Update_Duty --
      -----------------

      procedure Update_Duty (To : Integer) is
      begin
         if To /= Duty then
            Set_Duty (To);
            Display_Duty;
         end if;
      end Update_Duty;

      Command : Character;

   begin
      Console.Put_Line ("DC Motor control by L298");

      loop
         Console.Get (Command);

         case Command is
            when 'f' | 'F' =>
               Set_State (Forward);

            when 'b' | 'B' =>
               Set_State (Backward);

            when 's' | 'S' =>
               Set_State (Stop);

            when 'o' | 'O' =>
               Set_State (Off);

            when '1' =>
               Update_Duty (10);

            when '2' =>
               Update_Duty (30);

            when '3' =>
               Update_Duty (50);

            when '4' =>
               Update_Duty (70);

            when '5' =>
               Update_Duty (90);

            when '-' =>
               declare
                  Aux : Integer := Duty - 5;

               begin
                  if Aux < 1 then
                     Aux := 1;
                  end if;

                  Update_Duty (Aux);
               end;

            when '=' =>
               declare
                  Aux : Integer := Duty + 5;

               begin
                  if Aux > 99 then
                     Aux := 99;
                  end if;

                  Update_Duty (Aux);
               end;

            when '_' =>
               declare
                  Aux : Integer := Duty - 1;

               begin
                  if Aux < 1 then
                     Aux := 1;
                  end if;

                  Update_Duty (Aux);
               end;

            when '+' =>
               declare
                  Aux : Integer := Duty + 1;

               begin
                  if Aux > 99 then
                     Aux := 99;
                  end if;

                  Update_Duty (Aux);
               end;

            when 'a' | 'A' =>
               Do_ADC;
               Console.Put_Line ("ADC data collected");
               Process_ADC;

            when others =>
               null;
         end case;
      end loop;
   end Run;

   --------------
   -- Set_Duty --
   --------------

   procedure Set_Duty (To : Integer) is
      use type A0B.Types.Unsigned_32;

      CCR : A0B.Types.Unsigned_32;

   begin
      Duty := To;

      CCR := Cycle * A0B.Types.Unsigned_32 (Duty) / 100;

      if CCR /= 0 then
         CCR := CCR - 1;
      end if;

      A0B.STM32F401.SVD.TIM.TIM10_Periph.CCR1.CCR1 :=
        A0B.Types.Unsigned_16 (CCR);
   end Set_Duty;

   ---------------
   -- Set_State --
   ---------------

   procedure Set_State (To : State_Kind) is
   begin
      State := To;

      case State is
         when Forward =>
            IN1_Pin.Set (True);
            IN2_Pin.Set (False);
            Set_Duty (Duty);
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output.OC1M := 2#110#;
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1.CEN := True;

         when Backward =>
            IN1_Pin.Set (False);
            IN2_Pin.Set (True);
            Set_Duty (Duty);
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output.OC1M := 2#110#;
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1.CEN := True;

         when Stop =>
            IN1_Pin.Set (True);
            IN2_Pin.Set (True);
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output.OC1M := 2#101#;

         when Off =>
            IN1_Pin.Set (False);
            IN2_Pin.Set (False);
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CCMR1_Output.OC1M := 2#100#;
            A0B.STM32F401.SVD.TIM.TIM10_Periph.CR1.CEN := False;
      end case;
   end Set_State;
end DC_Motor_L298.Application;
