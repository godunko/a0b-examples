--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  with A0B.Callbacks.Generic_Parameterless;
with A0B.MPUXXXX;

with Awaits;
with Console;
with MPU9250_Calibration.Configuration;

package body MPU9250_Calibration.UI is

   ---------
   -- Run --
   ---------

   procedure Run is
      Message : constant String := "MPU9250 Calibrartion Utility";
      Command : Character;

   begin
      Console.Put_Line (Message);
      Console.New_Line;

      loop
         Console.Get (Command);

         case Command is
            when 'i' | 'I' =>
               declare
                  Success : Boolean := True;

               begin
                  MPU9250_Calibration.Configuration.IMU.Initialize
                    (Finished => Awaits.Create_Callback,
                     Success  => Success);

                  Awaits.Suspend_Until_Callback (Success);

                  if Success then
                     Console.Put_Line ("IMU: initialized");

                  else
                     Console.Put_Line ("IMU: initialization failed");
                  end if;

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
                     Console.Put ("IMU: configured");

                  else
                     Console.Put ("IMU: configuration failed");
                  end if;

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

            when 'q' | 'Q' =>
               Console.Put_Line ("It works, thanks!");

            when others =>
               Console.Put_Line ("Unknown command");
         end case;
      end loop;
   end Run;

end MPU9250_Calibration.UI;
