--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package A0B.STM32F401.TIM_Lines
  with Preelaborate, No_Elaboration_Code_All
is

   TIM10_CH1 : constant Function_Line_Descriptor;

private

   TIM10_CH1 : constant Function_Line_Descriptor :=
     [(B, 8, 3)];

end A0B.STM32F401.TIM_Lines;
