--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Parameterless;

with Button_LED.Configuration;

package body Button_LED.Application
  with Preelaborate
is

   procedure On_Key;

   package On_Key_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Key);

   State : Boolean := False;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Button_LED.Configuration.Initialize;

      Button_LED.Configuration.Key.Set_Callback
        (On_Key_Callbacks.Create_Callback);
      Button_LED.Configuration.Key.Enable_Interrupt;

      Button_LED.Configuration.LED.Set (State);
   end Initialize;

   ------------
   -- On_Key --
   ------------

   procedure On_Key is
   begin
      State := not State;
      Button_LED.Configuration.LED.Set (State);
   end On_Key;

end Button_LED.Application;
