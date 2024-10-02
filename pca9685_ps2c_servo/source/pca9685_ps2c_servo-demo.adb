--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.Callbacks.Generic_Parameterless;
with A0B.PCA9685;
with A0B.PlayStation2_Controllers.Protocol;
with A0B.Timer;

with PCA9685_PS2C_Servo.Configuration;

package body PCA9685_PS2C_Servo.Demo is

   PWM_Frequency : constant := 320;
   PWM_Min       : constant := 658;
   PWM_Max       : constant := 3289;

   Poll_Interval : constant := 0.01;

   procedure On_Initialization;

   procedure On_Poll;

   procedure On_Interval;

   package On_Initialization_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Initialization);

   package On_Poll_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Poll);

   package On_Interval_Callbacks is
     new A0B.Callbacks.Generic_Parameterless (On_Interval);

   type State_Kind is
     (Initial,
      PWM_Initialization,
      PWM_Configuration,
      PS2C_Enter_Configuration_Mode,
      PS2C_Enable_Analog_Mode,
      PS2C_Leave_Configuration_Mode,
      Ready,
      Poll);

   State          : State_Kind := Initial with Volatile;
   Interval_Timer : aliased A0B.Timer.Timeout_Control_Block;

   PS2C_Transmit_Buffer :
     A0B.PlayStation2_Controllers.Protocol.Communication_Buffer;
   PS2C_Receive_Buffer  :
     A0B.PlayStation2_Controllers.Protocol.Communication_Buffer;

   PS2C_State : A0B.PlayStation2_Controllers.Controller_State;

   -----------------------
   -- On_Initialization --
   -----------------------

   procedure On_Initialization is
      Success : Boolean := True;

   begin
      case State is
         when Initial =>
            PCA9685_PS2C_Servo.Configuration.PWM_Controller.Initialize
              (Finished => On_Initialization_Callbacks.Create_Callback,
               Success  => Success);

            State := PWM_Initialization;

         when PWM_Initialization =>
            State := PWM_Configuration;

            PCA9685_PS2C_Servo.Configuration.PWM_Controller.Configure
              (Frequency => PWM_Frequency,
               Finished  => On_Initialization_Callbacks.Create_Callback,
               Success   => Success);

         when PWM_Configuration =>
            State := PS2C_Enter_Configuration_Mode;

            A0B.PlayStation2_Controllers.Protocol.Packet_Encoder
              .Enter_Configuration_Mode (PS2C_Transmit_Buffer);

            PCA9685_PS2C_Servo.Configuration.PS2C_Controller.Transfer
              (Transmit_Buffer => PS2C_Transmit_Buffer,
               Receive_Buffer  => PS2C_Receive_Buffer,
               On_Completed    => On_Initialization_Callbacks.Create_Callback,
               Success         => Success);

         when PS2C_Enter_Configuration_Mode =>
            State := PS2C_Enable_Analog_Mode;

            A0B.PlayStation2_Controllers.Protocol.Packet_Encoder
              .Enable_Analog_Mode (PS2C_Transmit_Buffer, True);

            PCA9685_PS2C_Servo.Configuration.PS2C_Controller.Transfer
              (Transmit_Buffer => PS2C_Transmit_Buffer,
               Receive_Buffer  => PS2C_Receive_Buffer,
               On_Completed    => On_Initialization_Callbacks.Create_Callback,
               Success         => Success);

         when PS2C_Enable_Analog_Mode =>
            State := PS2C_Leave_Configuration_Mode;

            A0B.PlayStation2_Controllers.Protocol.Packet_Encoder
              .Leave_Configuration_Mode (PS2C_Transmit_Buffer);

            PCA9685_PS2C_Servo.Configuration.PS2C_Controller.Transfer
              (Transmit_Buffer => PS2C_Transmit_Buffer,
               Receive_Buffer  => PS2C_Receive_Buffer,
               On_Completed    => On_Initialization_Callbacks.Create_Callback,
               Success         => Success);

         when PS2C_Leave_Configuration_Mode =>
            State := Ready;

            On_Interval;

         when others =>
            raise Program_Error;
      end case;

      if not Success then
         raise Program_Error;
      end if;
   end On_Initialization;

   -----------------
   -- On_Interval --
   -----------------

   procedure On_Interval is
      Success : Boolean := True;

   begin
      A0B.PlayStation2_Controllers.Protocol.Packet_Encoder.Poll
        (PS2C_Transmit_Buffer);

      State := Poll;
      PCA9685_PS2C_Servo.Configuration.PS2C_Controller.Transfer
        (Transmit_Buffer => PS2C_Transmit_Buffer,
         Receive_Buffer  => PS2C_Receive_Buffer,
         On_Completed    => On_Poll_Callbacks.Create_Callback,
         Success         => Success);

      if not Success then
         raise Program_Error;
      end if;
   end On_Interval;

   -------------
   -- On_Poll --
   -------------

   procedure On_Poll is
      Value : Integer;

   begin
      A0B.PlayStation2_Controllers.Protocol.Packet_Decoder.Poll
        (PS2C_Receive_Buffer, PS2C_State);

      Value :=
        (Integer (PS2C_State.Right_Joystick_Horizontal) * (PWM_Max - PWM_Min))
          / 255 + PWM_Min;

      PCA9685_PS2C_Servo.Configuration.PWM_Controller.Channel_00.Set
        (0, A0B.PCA9685.Value_Type (Value));

      A0B.Timer.Enqueue
        (Interval_Timer,
         On_Interval_Callbacks.Create_Callback,
         Poll_Interval);
   end On_Poll;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      On_Initialization;
   end Run;

end PCA9685_PS2C_Servo.Demo;
