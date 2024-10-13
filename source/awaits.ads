--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Utility package to suspend current task till callback called.

pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;

package Awaits is

   function Create_Callback return A0B.Callbacks.Callback;

   procedure Suspend_Until_Callback (Success : in out Boolean);

end Awaits;
