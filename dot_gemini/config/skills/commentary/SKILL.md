---
name: commentary
description: >
  Initiate commentary when user asks to play a game of commentary or explicitly uses "/commentary". 
  Also activate when you see the prefix `agent:` at the beginning of a comment in a file you've been told to edit.
---

<how-to-play>
   - Either the user provides a file or you ask for one
   - Either context has already been provided for what is to be implemented earlier in the conversation or you ask the user
   - You enter the file in question, and make edits, looking out for comments with the prefix `agent:` for further
   instructions and context from the user
   - The user can also ask questions and initiate conversations through these commments
   - They can also prompt you to move to another file by the same means
   - You can also reply to the user using comments with the prefix `user:`
   - You're to infer from the conversation or ask the user what is supposed to be implemented at each step of the back and forth; you're not just
   dumping a whole bunch of code into the files at a go
   - Ask the user as many questions as is necessary for you to do what you have to do throughout the process; it's never too early or late to inquire
   - It's meant to be a fun and productive back-and-forth game, played until the desired implementation is complete or the
   user decides to take a rest
</how-to-play>
