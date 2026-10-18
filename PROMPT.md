# Copy-paste prompt

Open Claude Code (or another coding agent that can run commands on your computer), paste this one line, and press Enter:

```text
Set up an AI vault for me: https://github.com/kub-ski/ai-vault
```

That is all. The rest of this page is what your AI does with it, so it knows exactly how. If your AI asks for more detail, paste the longer version below.

## Longer version

```text
I want an AI vault: a folder of notes my AI can read, with memory that saves and loads automatically.

1. Clone https://github.com/kub-ski/ai-vault into ~/ai-vault-kit (if the folder exists, run `git pull` in it). Read README.md and PROMPT.md there.
2. Ask me these questions, one at a time, and wait for each answer:
   a) What is your name, and what do you do (work, studies, a business)?
   b) Which areas of work or life should get a folder? (for example: a shop, a class, a hobby, a side project). Two or three is enough; I can add more later.
   c) Where should the vault live? (default: ~/my-vault. If I use iCloud Drive, put it in iCloud Drive/my-vault.)
   d) Do I use Obsidian? (yes/no. If yes, tell me to open the folder as a vault, and to turn off "Use [[Wikilinks]]".)
   e) Should I keep a git history of the vault? (yes/no, default yes. It stays on this computer.)
   f) How do I like answers? (short or detailed, plain or formal, bullets or paragraphs)
3. Run ./scripts/install.sh <the folder I chose> (add --git if I said yes). Read its output. If the self-test at the end says FAILED, read the message, fix the cause, and run it again in a new empty folder.
4. Fill in <vault>/01-personal/identity.md and communication-prefs.md from my answers. Remove the "not filled in yet" note from identity.md. Create one folder in 02-work for each area I named, each with a one-line README.md, and add them to index.md.
5. Delete the 03-projects/example-project folder only after I say so. Offer to run /new-project for my first real project.
6. Tell me, in plain words: open Claude Code inside the vault folder, type /kickoff to start a session and /wrapup to finish one. Memory saves and loads on its own in between.
7. Show me one proof that the memory works: tell me to close Claude, open it again in the vault folder, and ask "what were we working on?".

Never use sudo and never ask me for a password or a secret key. Do not put any password or key in any file. Do not touch anything outside the vault folder and the kit folder. If something needs a step only I can do (like installing Apple's command line tools, a pop-up asking for my Mac password), explain it in plain words and wait until I say "done".

Use plain words. I am not technical. Do the commands yourself; do not ask me to run them.
```
