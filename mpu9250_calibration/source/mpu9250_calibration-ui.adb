--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Parameterless;
with A0B.STM32F401.USART;

with MPU9250_Calibration.Configuration;

package body MPU9250_Calibration.UI is

   package Awaits is

      function Create_Callback return A0B.Callbacks.Callback;

      procedure Suspend_Until_Callback;

   end Awaits;

   procedure Put (Item : String);

   procedure Get (Item : out Character);

   ------------
   -- Awaits --
   ------------

   package body Awaits is

      procedure On_Callback;

      package On_Callback_Callbacks is
        new A0B.Callbacks.Generic_Parameterless (On_Callback);

      Flag : Boolean with Volatile;

      ---------------------
      -- Create_Callback --
      ---------------------

      function Create_Callback return A0B.Callbacks.Callback is
      begin
         Flag := False;

         return On_Callback_Callbacks.Create_Callback;
      end Create_Callback;

      -----------------
      -- On_Callback --
      -----------------

      procedure On_Callback is
      begin
         Flag := True;
      end On_Callback;

      ----------------------------
      -- Suspend_Until_Callback --
      ----------------------------

      procedure Suspend_Until_Callback is
      begin
         while not Flag loop
            null;
         end loop;
      end Suspend_Until_Callback;

   end Awaits;

   ---------
   -- Get --
   ---------

   procedure Get (Item : out Character) is
      Buffers : A0B.STM32F401.USART.Buffer_Descriptor_Array (0 .. 0);
      Success : Boolean := True;

   begin
     Buffers (0) :=
        (Address     => Item'Address,
         Size        => 1,
         Transferred => <>,
         State       => <>);

      MPU9250_Calibration.Configuration.UART1.USART1_Asynchronous.Receive
        (Buffers  => Buffers,
         Finished => Awaits.Create_Callback,
         Success  => Success);

      if Success then
         Awaits.Suspend_Until_Callback;
      end if;
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (Item : String) is
      Buffers : A0B.STM32F401.USART.Buffer_Descriptor_Array (0 .. 0);
      Success : Boolean := True;

   begin
      Buffers (0) :=
        (Address     => Item (Item'First)'Address,
         Size        => Item'Length,
         Transferred => <>,
         State       => <>);

      MPU9250_Calibration.Configuration.UART1.USART1_Asynchronous.Transmit
        (Buffers  => Buffers,
         Finished => Awaits.Create_Callback,
         Success  => Success);

      if Success then
         Awaits.Suspend_Until_Callback;
      end if;
   end Put;

   ---------
   -- Run --
   ---------

   procedure Run is
      Hello   : constant String := "Hello!" & ASCII.CR & ASCII.LF;
      Message : constant String := "MPU9250 Calibrartion Utility" & ASCII.CR & ASCII.LF;
      Command : Character;

   begin
      Put (Hello);
      Put (Message);

      loop
         Get (Command);

         case Command is
            when 'i' | 'I' =>
               declare
                  Success : Boolean := True;

               begin
                  MPU9250_Calibration.Configuration.IMU.Initialize
                    (Finished => Awaits.Create_Callback,
                     Success  => Success);

                  if Success then
                     Awaits.Suspend_Until_Callback;

                     Put ("Initialized" & ASCII.CR & ASCII.LF);

                  else
                     Put ("Initialization failed" & ASCII.CR & ASCII.LF);
                  end if;
               end;

            when 'q' | 'Q' =>
               Put ("It works, thanks!" & ASCII.CR & ASCII.LF);

            when others =>
               Put ("Unknown command" & ASCII.CR & ASCII.LF);
         end case;
      end loop;
   end Run;

end MPU9250_Calibration.UI;
