--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Console API

pragma Restrictions (No_Elaboration_Code);

package Console is

   procedure Put (Item : Character);

   procedure Put (Item : String);

   procedure Put_Line (Item : String);

   procedure New_Line;

   procedure Get (Item : out Character);

end Console;
