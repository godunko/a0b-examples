--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Conversion;
with Interfaces;

with A0B.Callbacks.Generic_Parameterless;
with A0B.MPUXXXX;
with A0B.MPU9250;
with A0B.Time;
with A0B.Timer;
with A0B.Types;

with Awaits;
with Console;
with MPU9250_Calibration.Configuration;

package body MPU9250_Calibration.UI is

   procedure Collect_Data;

   procedure Calibration_Data;

   procedure On_Done;

   package Collect_Data_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (Collect_Data);

   package Calibration_Data_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (Calibration_Data);

   package On_Done_Callbacks is
      new A0B.Callbacks.Generic_Parameterless (On_Done);

   type Sensor_Data is record
      Data      : A0B.MPU9250.Sensor_Data;
      Timestamp : A0B.Time.Monotonic_Time;
   end record;

   Data : array (Positive range 1 .. 100) of Sensor_Data;
   Last : Natural := 0;
   Done : Boolean := False;

   --  Calibration_Item : Natural;

   Calibration_Accelerometer_X_Accumulated : A0B.Types.Integer_64;
   Calibration_Accelerometer_Y_Accumulated : A0B.Types.Integer_64;
   Calibration_Accelerometer_Z_Accumulated : A0B.Types.Integer_64;
   Calibration_Gyroscope_U_Accumulated     : A0B.Types.Integer_64;
   Calibration_Gyroscope_V_Accumulated     : A0B.Types.Integer_64;
   Calibration_Gyroscope_W_Accumulated     : A0B.Types.Integer_64;
   Calibration_Count                       : A0B.Types.Integer_64;
   Calibration_Done                        : Boolean;

   procedure Calibration_Data is
      use type A0B.Types.Integer_64;

      function To_I32 is
        new Ada.Unchecked_Conversion
                  (A0B.MPUXXXX.Angular_Velosity, A0B.Types.Integer_32);

      function To_I32 is
        new Ada.Unchecked_Conversion
              (A0B.MPUXXXX.Gravitational_Acceleration,
               A0B.Types.Integer_32);

      Data      : A0B.MPU9250.Sensor_Data;
      Timestamp : A0B.Time.Monotonic_Time;
      Success   : Boolean := True;

   begin
      Calibration_Count := @ + 1;

      MPU9250_Calibration.Configuration.IMU.Get (Data, Timestamp);

      Calibration_Accelerometer_X_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Acceleration_X));
      Calibration_Accelerometer_Y_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Acceleration_Y));
      Calibration_Accelerometer_Z_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Acceleration_Z));

      Calibration_Gyroscope_U_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Velocity_U));
      Calibration_Gyroscope_V_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Velocity_V));
      Calibration_Gyroscope_W_Accumulated :=
        @ + A0B.Types.Integer_64 (To_I32 (Data.Velocity_W));

      if Calibration_Count >= 1_000 then
         MPU9250_Calibration.Configuration.IMU.Disable
           (Finished => On_Done_Callbacks.Create_Callback,
            Success  => Success);

         Calibration_Done := True;
      end if;
   end Calibration_Data;

   ------------------
   -- Collect_Data --
   ------------------

   procedure Collect_Data is
      Success : Boolean := True;

   begin
      Last := @ + 1;

      MPU9250_Calibration.Configuration.IMU.Get
        (Data (Last).Data, Data (Last).Timestamp);

      if Last = Data'Last then
         MPU9250_Calibration.Configuration.IMU.Disable
           (Finished => On_Done_Callbacks.Create_Callback,
            Success  => Success);
         Done := True;
      end if;
   end Collect_Data;

   -------------
   -- On_Done --
   -------------

   procedure On_Done is
   begin
      --  raise Program_Error;
      null;
   end On_Done;

   ---------
   -- Run --
   ---------

   procedure Run is
      Message : constant String := "MPU9250 Calibrartion Utility";
      Command : Character;

   begin
      Console.Put_Line (Message);
      Console.New_Line;

      declare
         Success : Boolean := True;

      begin
         Console.Put ("IMU: initialization...");

         MPU9250_Calibration.Configuration.IMU.Initialize
           (Finished => Awaits.Create_Callback,
            Success  => Success);

         Awaits.Suspend_Until_Callback (Success);

         if Success then
            Console.Put_Line (" done.");

         else
            Console.Put_Line (" failed.");
         end if;

         Console.Put ("IMU: configuration...");

         MPU9250_Calibration.Configuration.IMU.Configure
           (Accelerometer_Range => A0B.MPUXXXX.FSR_16G,
            Gyroscope_Range     => A0B.MPUXXXX.FSR_2000DPS,
            Temperature         => True,
            Filter              => True,
            Sample_Rate         => 50,
            Finished            => Awaits.Create_Callback,
            Success             => Success);

         Awaits.Suspend_Until_Callback (Success);

         if Success then
            Console.Put_Line (" done.");

         else
            Console.Put_Line (" failed.");
         end if;
      end;

      loop
         Console.Get (Command);

         case Command is
            when 'g' | 'G' =>
               declare
                  use type Interfaces.IEEE_Float_64;

                  Gyroscope_U_Integrated : Interfaces.IEEE_Float_64;
                  Gyroscope_V_Integrated : Interfaces.IEEE_Float_64;
                  Gyroscope_W_Integrated : Interfaces.IEEE_Float_64;

                  Timeout : aliased A0B.Timer.Timeout_Control_Block;
                  Success : Boolean := True;

               begin
                  MPU9250_Calibration.Configuration.IMU.Set_Data_Ready_Callback
                    (Collect_Data_Callbacks.Create_Callback);

                  Console.Put ("IMU: enable...");

                  Last := Data'First - 1;
                  Done := False;

                  MPU9250_Calibration.Configuration.IMU.Enable
                    (Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line (" done.");

                  else
                     Console.Put_Line (" failed.");
                  end if;

                  Console.Put ("IMU: receiving...");

                  loop
                     A0B.Timer.Enqueue
                       (Timeout  => Timeout,
                        Callback => Awaits.Create_Callback,
                        T        => A0B.Time.Seconds (1));

                     Awaits.Suspend_Until_Callback (Success);

                     Console.Put (Natural'Image (Last));
                     Console.Put ("...");

                     exit when Done;
                  end loop;

                  Gyroscope_U_Integrated := 0.0;
                  Gyroscope_V_Integrated := 0.0;
                  Gyroscope_W_Integrated := 0.0;

                  Console.Put_Line (" done.");

                  Console.New_Line;

                  for Item of Data loop
                     Gyroscope_U_Integrated :=
                       @ + Interfaces.IEEE_Float_64 (Item.Data.Velocity_U) * (1.0 / 50.0);
                     Gyroscope_V_Integrated :=
                       @ + Interfaces.IEEE_Float_64 (Item.Data.Velocity_V) * (1.0 / 50.0);
                     Gyroscope_W_Integrated :=
                       @ + Interfaces.IEEE_Float_64 (Item.Data.Velocity_W) * (1.0 / 50.0);

                     Console.Put
                       (A0B.Types.Unsigned_64'Image
                          (A0B.Time.To_Nanoseconds (Item.Timestamp)));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_X));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_Y));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_Z));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_U));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_V));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_W));
                     Console.Put
                       (A0B.MPUXXXX.Temperature'Image
                          (Item.Data.Temperature));
                     Console.New_Line;
                  end loop;

                  Console.Put (Interfaces.IEEE_Float_64'Image (Gyroscope_U_Integrated));
                  Console.Put (Interfaces.IEEE_Float_64'Image (Gyroscope_V_Integrated));
                  Console.Put (Interfaces.IEEE_Float_64'Image (Gyroscope_W_Integrated));

                  Console.New_Line;
               end;

            when 'c' | 'C' =>
               declare
                  use type A0B.Types.Integer_64;
                  use type A0B.MPUXXXX.Angular_Velosity;
                  use type A0B.MPUXXXX.Gravitational_Acceleration;

                  function To_AV is
                    new Ada.Unchecked_Conversion
                          (A0B.Types.Integer_32, A0B.MPUXXXX.Angular_Velosity);

                  function To_GA is
                    new Ada.Unchecked_Conversion
                      (A0B.Types.Integer_32,
                       A0B.MPUXXXX.Gravitational_Acceleration);

                  Calibration_Data : A0B.MPU9250.Calibration_Data;
                  Acceleration_X   : A0B.MPUXXXX.Gravitational_Acceleration;
                  Acceleration_Y   : A0B.MPUXXXX.Gravitational_Acceleration;
                  Acceleration_Z   : A0B.MPUXXXX.Gravitational_Acceleration;
                  Velocity_U       : A0B.MPUXXXX.Angular_Velosity;
                  Velocity_V       : A0B.MPUXXXX.Angular_Velosity;
                  Velocity_W       : A0B.MPUXXXX.Angular_Velosity;
                  Timeout          : aliased A0B.Timer.Timeout_Control_Block;
                  Success          : Boolean := True;

                  Accelerometer_Precision : constant := 2 ** 3;
                  Gyroscope_Precision     : constant := 2 ** 2 * 1_000;

               begin
                  --  Get active calibration information

                  Console.Put ("IMU: get calibration data...");

                  MPU9250_Calibration.Configuration.IMU.Get_Calibration
                    (Data     => Calibration_Data,
                     Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line (" done.");

                  else
                     Console.Put_Line (" failed.");
                  end if;

                  --  Enable IMU to receive and process data

                  MPU9250_Calibration.Configuration.IMU.Set_Data_Ready_Callback
                    (Calibration_Data_Callbacks.Create_Callback);

                  Console.Put ("IMU: enable...");

                  Calibration_Accelerometer_X_Accumulated := 0;
                  Calibration_Accelerometer_Y_Accumulated := 0;
                  Calibration_Accelerometer_Z_Accumulated := 0;
                  Calibration_Gyroscope_U_Accumulated     := 0;
                  Calibration_Gyroscope_V_Accumulated     := 0;
                  Calibration_Gyroscope_W_Accumulated     := 0;
                  Calibration_Count                       := 0;
                  Calibration_Done                        := False;

                  MPU9250_Calibration.Configuration.IMU.Enable
                    (Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line (" done.");

                  else
                     Console.Put_Line (" failed.");
                  end if;

                  Console.Put ("IMU: receiving...");

                  loop
                     A0B.Timer.Enqueue
                       (Timeout  => Timeout,
                        Callback => Awaits.Create_Callback,
                        T        => A0B.Time.Seconds (1));

                     Awaits.Suspend_Until_Callback (Success);

                     Console.Put
                       (A0B.Types.Integer_64'Image (Calibration_Count));
                     Console.Put ("...");

                     exit when Calibration_Done;
                  end loop;

                  Console.Put_Line (" done.");
                  Console.New_Line;

                  A0B.MPU9250.Get
                    (Data           => Calibration_Data,
                     Acceleration_X => Acceleration_X,
                     Acceleration_Y => Acceleration_Y,
                     Acceleration_Z => Acceleration_Z,
                     Velocity_U     => Velocity_U,
                     Velocity_V     => Velocity_V,
                     Velocity_W     => Velocity_W);

                  Console.Put ("Initial:    ");
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_X));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_Y));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_Z));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_U));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_V));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_W));
                  Console.New_Line;

                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_X_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_Y_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_Z_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_U_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_V_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_W_Accumulated));
                  Console.New_Line;

                  Calibration_Accelerometer_X_Accumulated :=
                    @ / Calibration_Count;
                  Calibration_Accelerometer_Y_Accumulated :=
                    @ / Calibration_Count;
                  Calibration_Accelerometer_Z_Accumulated :=
                    @ / Calibration_Count;
                  Calibration_Gyroscope_U_Accumulated :=
                    @ / Calibration_Count;
                  Calibration_Gyroscope_V_Accumulated :=
                    @ / Calibration_Count;
                  Calibration_Gyroscope_W_Accumulated :=
                    @ / Calibration_Count;

                  Calibration_Accelerometer_Z_Accumulated :=
                    @ + (if Calibration_Accelerometer_Z_Accumulated < 0
                           then 16_384
                           else -16_384);

                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_X_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_Y_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Accelerometer_Z_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_U_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_V_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Calibration_Gyroscope_W_Accumulated));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Accelerometer_Precision));
                  Console.Put
                    (A0B.Types.Integer_64'Image (Gyroscope_Precision));
                  Console.New_Line;


                  Console.Put ("Correction: ");
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (-To_GA
                           (A0B.Types.Integer_32
                              (Calibration_Accelerometer_X_Accumulated))));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (-To_GA
                          (A0B.Types.Integer_32
                             (Calibration_Accelerometer_Y_Accumulated))));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (-To_GA
                          (A0B.Types.Integer_32
                             (Calibration_Accelerometer_Z_Accumulated))));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (-To_AV
                          (A0B.Types.Integer_32
                             (Calibration_Gyroscope_U_Accumulated))));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (-To_AV
                          (A0B.Types.Integer_32
                             (Calibration_Gyroscope_V_Accumulated))));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (-To_AV
                          (A0B.Types.Integer_32
                                 (Calibration_Gyroscope_W_Accumulated))));

                  if abs Calibration_Accelerometer_X_Accumulated > Accelerometer_Precision then
                     Console.Put (" AX");
                     Acceleration_X :=
                       @ - To_GA
                             (A0B.Types.Integer_32
                                (Calibration_Accelerometer_X_Accumulated));
                  end if;

                  if abs Calibration_Accelerometer_Y_Accumulated > Accelerometer_Precision then
                     Console.Put (" AY");
                     Acceleration_Y :=
                       @ - To_GA
                             (A0B.Types.Integer_32
                                (Calibration_Accelerometer_Y_Accumulated));
                  end if;

                  if abs Calibration_Accelerometer_Z_Accumulated > Accelerometer_Precision then
                     Console.Put (" AZ");
                     Acceleration_Z :=
                       @ - To_GA
                             (A0B.Types.Integer_32
                                (Calibration_Accelerometer_Z_Accumulated));
                  end if;

                  if abs Calibration_Gyroscope_U_Accumulated > Gyroscope_Precision then
                     Console.Put (" VU");
                     Velocity_U :=
                       @ - To_AV
                             (A0B.Types.Integer_32
                                (Calibration_Gyroscope_U_Accumulated));
                  end if;

                  if abs Calibration_Gyroscope_V_Accumulated > Gyroscope_Precision then
                     Console.Put (" VV");
                     Velocity_V :=
                       @ - To_AV
                             (A0B.Types.Integer_32
                                (Calibration_Gyroscope_V_Accumulated));
                  end if;

                  if abs Calibration_Gyroscope_W_Accumulated > Gyroscope_Precision then
                     Console.Put (" VW");
                     Velocity_W :=
                       @ - To_AV
                             (A0B.Types.Integer_32
                                (Calibration_Gyroscope_W_Accumulated));
                  end if;

                  Console.New_Line;

                  Console.Put ("Recomputed: ");
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_X));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_Y));
                  Console.Put
                    (A0B.MPUXXXX.Gravitational_Acceleration'Image
                       (Acceleration_Z));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_U));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_V));
                  Console.Put
                    (A0B.MPUXXXX.Angular_Velosity'Image
                       (Velocity_W));
                  Console.New_Line;


                  --  for Item of Data loop
                  --     Console.Put
                  --       (A0B.Types.Unsigned_64'Image
                  --          (A0B.Time.To_Nanoseconds (Item.Timestamp)));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                  --          (Item.Data.Acceleration_X));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                  --          (Item.Data.Acceleration_Y));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                  --          (Item.Data.Acceleration_Z));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Angular_Velosity'Image
                  --          (Item.Data.Velocity_U));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Angular_Velosity'Image
                  --          (Item.Data.Velocity_V));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Angular_Velosity'Image
                  --          (Item.Data.Velocity_W));
                  --     Console.Put
                  --       (A0B.MPUXXXX.Temperature'Image
                  --          (Item.Data.Temperature));
                  --     Console.New_Line;
                  --  end loop;
                  --

                  Console.Put ("IMU: set calibration...");

                  A0B.MPU9250.Set
                    (Data           => Calibration_Data,
                     Acceleration_X => Acceleration_X,
                     Acceleration_Y => Acceleration_Y,
                     Acceleration_Z => Acceleration_Z,
                     Velocity_U     => Velocity_U,
                     Velocity_V     => Velocity_V,
                     Velocity_W     => Velocity_W);

                  MPU9250_Calibration.Configuration.IMU.Set_Calibration
                    (Data     => Calibration_Data,
                     Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line (" done.");

                  else
                     Console.Put_Line (" failed.");
                  end if;

                  Console.New_Line;
               end;


            when 'o' | 'O' =>
               declare
                  Success : Boolean := True;

               begin
                  Last := Data'First - 1;

                  MPU9250_Calibration.Configuration.IMU.Enable
                    (Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line ("IMU: enabled");

                  else
                     Console.Put_Line ("IMU: enable failed");
                  end if;
               end;

            when 'd' | 'D' =>
               declare
                  use type A0B.Types.Integer_64;

                  function To_I32 is
                    new Ada.Unchecked_Conversion
                          (A0B.MPUXXXX.Angular_Velosity, A0B.Types.Integer_32);

                  function To_I32 is
                    new Ada.Unchecked_Conversion
                          (A0B.MPUXXXX.Gravitational_Acceleration,
                           A0B.Types.Integer_32);

                  function To_AV is
                    new Ada.Unchecked_Conversion
                          (A0B.Types.Integer_32, A0B.MPUXXXX.Angular_Velosity);

                  function To_GA is
                    new Ada.Unchecked_Conversion
                      (A0B.Types.Integer_32,
                       A0B.MPUXXXX.Gravitational_Acceleration);

                  No_Callback : A0B.Callbacks.Callback;
                  Success     : Boolean := True;

                  AX : A0B.Types.Integer_64 := 0;
                  AY : A0B.Types.Integer_64 := 0;
                  AZ : A0B.Types.Integer_64 := 0;

                  GU : A0B.Types.Integer_64 := 0;
                  GV : A0B.Types.Integer_64 := 0;
                  GW : A0B.Types.Integer_64 := 0;

                  D  : A0B.MPU9250.Calibration_Data;

               begin
                  for Item of Data loop
                     Console.Put
                       (A0B.Types.Unsigned_64'Image
                          (A0B.Time.To_Nanoseconds (Item.Timestamp)));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_X));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_Y));
                     Console.Put
                       (A0B.MPUXXXX.Gravitational_Acceleration'Image
                          (Item.Data.Acceleration_Z));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_U));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_V));
                     Console.Put
                       (A0B.MPUXXXX.Angular_Velosity'Image
                          (Item.Data.Velocity_W));
                     Console.Put
                       (A0B.MPUXXXX.Temperature'Image
                          (Item.Data.Temperature));
                     Console.New_Line;

                     AX :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Acceleration_X));
                     AY :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Acceleration_Y));
                     AZ :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Acceleration_Z));

                     GU :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Velocity_U));
                     GV :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Velocity_V));
                     GW :=
                       @ + A0B.Types.Integer_64
                             (To_I32 (Item.Data.Velocity_W));
                  end loop;

                  Console.New_Line;
                  Console.Put (A0B.Types.Integer_64'Image (AX));
                  Console.Put (A0B.Types.Integer_64'Image (AY));
                  Console.Put (A0B.Types.Integer_64'Image (AZ));
                  Console.Put (A0B.Types.Integer_64'Image (GU));
                  Console.Put (A0B.Types.Integer_64'Image (GV));
                  Console.Put (A0B.Types.Integer_64'Image (GW));
                  Console.New_Line;

                  AX := @ / Data'Length;
                  AY := @ / Data'Length;
                  AZ := @ / Data'Length;
                  GU := @ / Data'Length;
                  GV := @ / Data'Length;
                  GW := @ / Data'Length;

                  Console.Put (A0B.Types.Integer_64'Image (AX));
                  Console.Put (A0B.Types.Integer_64'Image (AY));
                  Console.Put (A0B.Types.Integer_64'Image (AZ));
                  Console.Put (A0B.Types.Integer_64'Image (GU));
                  Console.Put (A0B.Types.Integer_64'Image (GV));
                  Console.Put (A0B.Types.Integer_64'Image (GW));
                  Console.New_Line;

                  A0B.MPU9250.Set
                    (Data           => D,
                     Acceleration_X => To_GA (A0B.Types.Integer_32 (-AX)),
                     Acceleration_Y => To_GA (A0B.Types.Integer_32 (-AY)),
                     Acceleration_Z => To_GA (A0B.Types.Integer_32 (-AZ)),
                     Velocity_U     => To_AV (A0B.Types.Integer_32 (-GU)),
                     Velocity_V     => To_AV (A0B.Types.Integer_32 (-GV)),
                     Velocity_W     => To_AV (A0B.Types.Integer_32 (-GW)));
                  MPU9250_Calibration.Configuration.IMU.Set_Calibration
                    (Data => D, Finished => No_Callback, Success => Success);
               end;

            when 'q' | 'Q' =>
               Console.Put_Line ("It works, thanks!");

            when others =>
               Console.Put_Line ("Unknown command");
         end case;
      end loop;
   end Run;

end MPU9250_Calibration.UI;
