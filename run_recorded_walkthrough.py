#!/usr/bin/env python3
"""
Interactive ChatBot & Live Web Search Tutorial Walkthrough for SSCodeIDE
- Selects Laguna Code model
- Tests /web AgroCIA and /search AgroCIA demonstrating live web snippets and links
- Tests intimate 'Tu' conversational prompts
- Tests Agent Mode file generation
- Records to tutorial_recording.mkv
"""

import time
import os
import subprocess
import pyautogui

pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0.4

SCREEN_W, SCREEN_H = pyautogui.size()

def smooth_move(x, y, duration=0.8):
    pyautogui.moveTo(x, y, duration=duration, tween=pyautogui.easeInOutQuad)

def main():
    print(f"[Walkthrough] Screen resolution: {SCREEN_W}x{SCREEN_H}")

    recording_file = "/home/mcaquart/Downloads/SSCodeIDE_Godot/tutorial_recording.mkv"
    print(f"[Walkthrough] Starting screen recording to {recording_file}...")
    ssr_proc = subprocess.Popen(
        ["simplescreenrecorder", "--start-hidden", "--start-recording"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    time.sleep(2)

    print("[Walkthrough] Launching Godot SSCodeIDE with Laguna model...")
    godot_proc = subprocess.Popen(
        ["/home/mcaquart/bin/godot", "--path", "/home/mcaquart/Downloads/SSCodeIDE_Godot"]
    )
    time.sleep(5.0)

    try:
        chat_input_x = SCREEN_W - 240
        chat_input_y = SCREEN_H - 70

        # Scene 1: Test /web AgroCIA
        print("[Walkthrough] Scene 1: Testing '/web AgroCIA'...")
        smooth_move(chat_input_x, chat_input_y, 0.9)
        pyautogui.click()
        time.sleep(0.4)
        pyautogui.typewrite("/web AgroCIA", interval=0.03)
        time.sleep(0.4)
        pyautogui.press('enter')
        time.sleep(3.5)

        # Scene 2: Test /search AgroCIA
        print("[Walkthrough] Scene 2: Testing '/search AgroCIA'...")
        smooth_move(chat_input_x, chat_input_y, 0.5)
        pyautogui.click()
        time.sleep(0.3)
        pyautogui.typewrite("/search AgroCIA", interval=0.03)
        time.sleep(0.4)
        pyautogui.press('enter')
        time.sleep(3.5)

        # Scene 3: Conversing with Laguna in 'Tu'
        print("[Walkthrough] Scene 3: Conversing with Laguna Code in 'Tu'...")
        smooth_move(chat_input_x, chat_input_y, 0.5)
        pyautogui.click()
        time.sleep(0.3)
        prompt_1 = "Ola! Podes resumir-me o que encontraste sobre a AgroCIA e como poderiamos integrar uma API REST em GDScript?"
        pyautogui.typewrite(prompt_1, interval=0.02)
        time.sleep(0.5)
        pyautogui.press('enter')

        smooth_move(SCREEN_W - 250, 450, 1.2)
        print("[Walkthrough] Waiting for AI response...")
        time.sleep(7.5)

        # Scene 4: Agent Mode File Creation
        print("[Walkthrough] Scene 4: Agent Mode file creation...")
        agent_btn_x = SCREEN_W - 130
        agent_btn_y = 60
        smooth_move(agent_btn_x, agent_btn_y, 0.8)
        pyautogui.click()
        time.sleep(0.8)

        smooth_move(chat_input_x, chat_input_y, 0.8)
        pyautogui.click()
        time.sleep(0.4)
        prompt_2 = "Optimo! Podes criar o ficheiro 'scripts/agrocia_api_client.gd' com uma classe GDScript para comunicar com a API?"
        pyautogui.typewrite(prompt_2, interval=0.02)
        time.sleep(0.5)
        pyautogui.press('enter')

        smooth_move(SCREEN_W - 250, 600, 1.2)
        print("[Walkthrough] Waiting for AI file generation...")
        time.sleep(8.0)

        # Scene 5: Inspecting editor
        smooth_move(SCREEN_W // 2, 350, 1.0)
        time.sleep(1.5)

        print("[Walkthrough] Walkthrough completed successfully!")

    finally:
        print("[Walkthrough] Terminating Godot...")
        godot_proc.terminate()
        try:
            godot_proc.wait(timeout=3)
        except Exception:
            godot_proc.kill()

        print("[Walkthrough] Saving screen recording...")
        try:
            ssr_proc.stdin.write("record-save\nquit\n")
            ssr_proc.stdin.flush()
            time.sleep(2)
        except Exception as e:
            print("[Walkthrough] SSR stdin write error:", e)
        ssr_proc.terminate()
        try:
            ssr_proc.wait(timeout=3)
        except Exception:
            ssr_proc.kill()

    print(f"[Walkthrough] Screen recording saved to {recording_file}")

if __name__ == "__main__":
    main()
