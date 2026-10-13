# Project 5 - *Trivia Challenge*

Submitted by: **Trina Tabassum**

**Trivia Challenge** is a customizable trivia quiz app for iOS built using SwiftUI and the Open Trivia Database API. Users can configure quiz parameters—including topic categories, question count, difficulty level, question format, and an active countdown timer—play through interactive question cards, and view an instant score breakdown and detailed answer review upon completion.

Time spent: **3** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] App launches to an Options screen where user can modify the types of questions presented when the game starts. Users should be able to choose:
  - [x] Number of questions
  - [x] Category of questions
  - [x] Difficulty of questions
  - [x] Type of questions (Multiple Choice or True False)
- [x] User can tap a button to start trivia game, this presents questions and answers in a List or Card view.
  - Hint: For Card view visit your FlashCard app. List view is an equivalent to UITableView in UIKit. Much easier to use!
- [x] Selected choices are marked as user taps their choice (but answered is not presented yet!)
- [x] User can submit choices and is presented with a score on trivia game
 
The following **optional** features are implemented:

- [x] User has answer marked as correct or incorrect after submitting choices (alongside their score).
- [x] Implement a timer that puts pressure on the user! Choose any time that works and auto submit choices after the timer expires. 

The following **additional** features are implemented:

- [x] Configurable timer duration picker (30s, 60s, 120s, 300s, 1 hour) directly on the setup screen.
- [x] Robust API response handling with native alert popups for "No Results" (API Response Code 1) queries.
- [x] HTML entity decoding for API question and answer strings (handling `&quot;`, `&#039;`, `&amp;`, `&Eacute;`, etc.).
- [x] Smooth `< Back` navigation bar button to reset from the score review screen back to the setup menu.

## Video Walkthrough

Here's a walkthrough of implemented user stories:

[Watch the Walkthrough Video](https://tinyurl.com/mt6u43cu)

## Notes

- **Decoding HTML Entities:** The Open Trivia Database API returns questions and answers containing raw HTML character entities (such as `&#039;` for apostrophes and `&quot;` for quotation marks). Implemented string cleaning to ensure text rendered cleanly across all cards.
- **Handling Empty Query Results:** Some niche combinations (e.g., 10 hard True/False questions in Science & Nature) return an API response code of `1` (No Results). Implemented a custom enum and SwiftUI alert so users receive clear error feedback rather than an empty screen.
- **Timer and State Coordination:** Synchronized a `Timer.publish` autoconnected publisher with auto-submission logic and interactive answer selections without triggering early view dismissals.

## License

    Copyright 2026 Trina Tabassum

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
