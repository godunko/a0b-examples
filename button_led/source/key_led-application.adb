--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Parameterless;

with Key_LED.Configuration;

package body Key_LED.Application
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
      Key_LED.Configuration.Initialize;

      Key_LED.Configuration.Key.Set_Callback (On_Key_Callbacks.Create_Callback);
      Key_LED.Configuration.Key.Enable_Interrupt;

      Key_LED.Configuration.LED.Set (State);
   end Initialize;

   ------------
   -- On_Key --
   ------------

   procedure On_Key is
   begin
      State := not State;
      Key_LED.Configuration.LED.Set (State);
   end On_Key;

end Key_LED.Application;
