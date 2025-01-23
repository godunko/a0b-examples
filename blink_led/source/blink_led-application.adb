--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Parameterless;
with A0B.Timer;

with Blink_LED.Configuration;

package body Blink_LED.Application
  with Preelaborate
is

   procedure On_Timer;

   package On_Timer_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Timer);

   Timer : aliased A0B.Timer.Timeout_Control_Block;
   State : Boolean := False;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Blink_LED.Configuration.LED.Set (State);

      A0B.Timer.Enqueue (Timer, On_Timer_Callbacks.Create_Callback, 1.0);
   end Initialize;

   --------------
   -- On_Timer --
   --------------

   procedure On_Timer is
   begin
      State := not State;
      Blink_LED.Configuration.LED.Set (State);

      A0B.Timer.Enqueue (Timer, On_Timer_Callbacks.Create_Callback, 1.0);
   end On_Timer;

end Blink_LED.Application;
