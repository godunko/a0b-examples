--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package A0B.STM32F401.TIM_Lines
  with Preelaborate, No_Elaboration_Code_All
is

   TIM3_CH1  : constant Function_Line_Descriptor;
   TIM3_CH2  : constant Function_Line_Descriptor;
   TIM3_CH3  : constant Function_Line_Descriptor;
   TIM3_CH4  : constant Function_Line_Descriptor;
   TIM4_CH1  : constant Function_Line_Descriptor;
   TIM4_CH2  : constant Function_Line_Descriptor;
   TIM4_CH3  : constant Function_Line_Descriptor;
   TIM4_CH4  : constant Function_Line_Descriptor;

   TIM9_CH1  : constant Function_Line_Descriptor;
   TIM9_CH2  : constant Function_Line_Descriptor;
   TIM10_CH1 : constant Function_Line_Descriptor;
   TIM11_CH1 : constant Function_Line_Descriptor;

private

   TIM3_CH1  : constant Function_Line_Descriptor :=
     [(A, 6, 2), (B, 4, 2), (C, 6, 2)];
   TIM3_CH2  : constant Function_Line_Descriptor :=
     [(A, 7, 2), (B, 5, 2), (C, 7, 2)];
   TIM3_CH3  : constant Function_Line_Descriptor := [(B, 0, 2), (C, 8, 2)];
   TIM3_CH4  : constant Function_Line_Descriptor := [(B, 1, 2), (C, 9, 2)];
   TIM4_CH1  : constant Function_Line_Descriptor := [(B, 6, 2), (D, 12, 2)];
   TIM4_CH2  : constant Function_Line_Descriptor := [(B, 7, 2), (D, 13, 2)];
   TIM4_CH3  : constant Function_Line_Descriptor := [(B, 8, 2), (D, 14, 2)];
   TIM4_CH4  : constant Function_Line_Descriptor := [(B, 9, 2), (D, 15, 2)];

   TIM9_CH1  : constant Function_Line_Descriptor := [(A, 2, 3), (E, 5, 3)];
   TIM9_CH2  : constant Function_Line_Descriptor := [(A, 3, 3), (E, 6, 3)];
   TIM10_CH1 : constant Function_Line_Descriptor := [(B, 8, 3)];
   TIM11_CH1 : constant Function_Line_Descriptor := [(B, 9, 3)];

end A0B.STM32F401.TIM_Lines;
