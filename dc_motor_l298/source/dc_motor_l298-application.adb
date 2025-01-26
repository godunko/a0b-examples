--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.GPIO.PIOB;
with A0B.STM32F401.SVD.RCC;
with A0B.STM32F401.SVD.TIM;
with A0B.STM32F401.TIM_Lines;
with A0B.Types;

with Console;

package body DC_Motor_L298.Application is

   use type A0B.Types.Unsigned_16;

   ENA_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB8;
   IN1_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB7;
   IN2_Pin : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB6;

   type State_Kind is (Forward, Backward, Stop, Off);

   State : State_Kind := Off;
   Duty  : Integer range 0 .. 100 := 50;

   procedure Set_State (To : State_Kind);

   procedure Set_Duty (To : Integer);

   --  Prescale : constant := 2_100;
   --  Prescale : constant := 210;    --  4/210/1000 = 100 Hz
   Divider  : constant := 2#00#;  --  1
   --  Prescale : constant := 21;     --  4/21/1000 = 1kHz
   Prescale : constant := 1;
   Cycle    : constant := 1_000;

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
   end Initialize;

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
