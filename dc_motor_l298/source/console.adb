--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

with A0B.STM32F401.USART;

with Awaits;
with Configuration;

package body Console is

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

      Configuration.UART1.USART1_Asynchronous.Receive
        (Buffers  => Buffers,
         Finished => Awaits.Create_Callback,
         Success  => Success);

      Awaits.Suspend_Until_Callback (Success);
   end Get;

   --------------
   -- New_Line --
   --------------

   procedure New_Line is
   begin
      Put (ASCII.CR & ASCII.LF);
   end New_Line;

   ---------
   -- Put --
   ---------

   procedure Put (Item : Character) is
      Buffer : String (1 .. 1);

   begin
      Buffer (Buffer'First) := Item;
      Put (Buffer);
   end Put;

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

      Configuration.UART1.USART1_Asynchronous.Transmit
        (Buffers  => Buffers,
         Finished => Awaits.Create_Callback,
         Success  => Success);

      Awaits.Suspend_Until_Callback (Success);
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : String) is
   begin
      Put (Item);
      New_Line;
   end Put_Line;

end Console;
