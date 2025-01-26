--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  It is non-tasking implementation for ARMv7-M architecture

pragma Restrictions (No_Elaboration_Code);

with A0B.ARMv7M.Instructions;
with A0B.Callbacks.Generic_Parameterless;

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

   procedure Suspend_Until_Callback (Success : in out Boolean) is
      pragma Warnings (Off, Success);

   begin
      if not Success then
         return;
      end if;

      while not Flag loop
         A0B.ARMv7M.Instructions.Wait_For_Interrupt;
      end loop;
   end Suspend_Until_Callback;

end Awaits;
