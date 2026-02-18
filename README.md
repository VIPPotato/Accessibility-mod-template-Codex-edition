# Welcome!

<!-- fork-note:start -->
## Fork Note

This repository is a fork of [HappyStarfish/Accessibility-mod-template](https://github.com/HappyStarfish/Accessibility-mod-template).

In this fork, assistant naming was normalized to Codex, and agent-file references were normalized to `AGENTS.md` so Codex can follow the guides more reliably.

I tested this modified template with GPT-5.3 Codex (the latest OpenAI model available at the time of testing), and it worked very well in practice. I hope this helps people who need larger usage limits.

Huge thanks to **Plueschyoda** for creating the original template.
<!-- fork-note:end -->

So you've seen some impressive examples of people creating entire complex mods with the help of AI, and you've been wondering if you could do the same?

I definitely wanted to find out, and I haven't found a comprehensive guide, so I've decided to create my own while I learned myself how to do this. Which then turned into the idea to make a whole template which allows people to dive right into mod development without hours of preparation.

## Important Disclaimer

This is very much work in progress. I have not finished any actual mod using this template yet—just started way too many in order to make sure that the basics are covered. Once you're in the middle of the process though, Codex generally knows very well how to proceed.

Be aware: It takes some patience, and you'll want sufficient model usage limits.

So let's get you started...

## Prerequisites and Preparations

### What You'll Need

As mentioned, you'll need an OpenAI account with Codex access, plus billing enabled if required in your region.

After signup, install Codex CLI on your computer and run it in your project folder.

### Setting Up Your Environment

**Important:** Open your command line as an administrator.

Additionally, you'll need to install Git Bash, a command line tool Codex can use for handling certain requests. To check if Git Bash is already installed, run:
```
git --version
```

### Choosing Your Game

It seems to be the easiest (or at least the most popular) choice to mod games which are running on the Unity engine because there are great modding tools available for this. Maybe start with something small. Though it's OK if you don't.

We all have those games which we've been enthusiastic about for years on end and now we finally want to actually play them. In fact, the more enthusiastic you are about your game of choice, the more likely it is that you'll actually stay on track throughout weeks or maybe months of endless back and forth with the AI, fixing loads of mysterious bugs.

### Starting Your Project

1. Unpack the Accessibility-Mod-Template folder from this directory anywhere on your computer
2. Rename it to the game you want to modify
3. Open your newly created folder (without a file or subfolder being selected)
4. Open Windows PowerShell via the context menu (T or Alt+T usually works)
5. Type "codex" and go through the login process

**Tip:** Only during this login process, the command line output might not be very readable with your screen reader. Use OCR or sighted assistance if needed, and don't worry—as soon as it's set up, it runs very smoothly, reading out all contents automatically (at least with NVDA). Depending on your keyboard layout, you can either use some keys on your numpad or NVDA+Arrow Up to browse through the recent output.

**Note:** If any of you uses JAWS, could you please let me know how and to what extent the command line navigation works? Then I can add that info here.

### Getting started

1. Restart the command line (i.e. close the window, open the command line again via the context menu in the same folder, and type "codex")
2. Simply type something like "hello" or "new project"
3. The setup process will guide you through all the steps to get you started with the foundation of your mod development

## What the general workflow will look like

The first time you run the starting setup, Codex will prompt you to install several tools e.g. for logging and other technical background stuff. This will take a little while.
Then, after you've answered all the initial questions, e.g. where the game is located and what engine it is based on, Codex will guide you through some additional steps in order to get a first overview of what will need to be done to make the game accessible.
Then the actual work begins: You can decide which features you'll want to build first. I'd recommend to start with a very basic version which just announces something when the game is started, and then move on to the first things you'll interact with in the game, like the main menu or starting screen.
The AI will write a lot of code and test it (this is just for technical errors, not for actual functionality), then you can start the game, see what the mod does, and tell Codex what is not working.
And once the first feature is functional (or functional enough for the moment), you can continue with the next one.

## Tips and Tricks

Just a short version for now, I'll add more later:

### 1. Communicate Naturally

Talk to Codex in a dynamic, natural way. It's surprising how flexible it is, and it can figure out pretty much any creative solution you ask it about. (And now, it did not force me to write this!)

### 2. Be curious, creative and persistent

You can and should ask Codex to clarify things you don't get.
The better you understand what it is doing and why, the better suggestions you'll be able to make, no matter your level of coding skills (or lack thereof).
If you aren't sure how to proceed or which choice would be better, ask for advantages, disadvantages and common pitfalls.
Also, if you feel confident enough, do question Codex's decisions, sometimes it's possible to save yourself time (and tokens) by asking if a new feature can be built using already existing code.

### 3. What to do when something won't work even after the umteenth attempt

Sometimes it helps to urge Codex to check the existing source code for expected game behaviour. Maybe the dialogue popup you've been working on for hours doesn't actually exist because the game is doing something entirely different. Or maybe the combat handling class is using generic variable terms instead of the ones the game actually uses. (I did try to make Codex always check the source code, but honestly, it doesn't seem to be working that well.)

### 4. Manage Your Token Usage

It will quickly become important to be careful with your usage. Within a conversation, Codex will keep rereading everything that's been said every single time you send a new message. That's generally helpful because you want the AI to remember what you're doing, but if possible, start a new conversation whenever one topic or little feature is completed.

### 5. Maintain Documentation

Add and maintain documentation in MD files to make Codex remember things across conversations. The template setup will start doing this already. The most important file is `AGENTS.md`—everything that's really important should go there. However, it will be read every single time you interact with Codex, so make sure it stays short and compact.

---

Have fun, and do let me know how it goes! Either here or on the Audiogames forum.

The rest of this page is just credits and technical stuff for GitHub.


## Project Structure

- `Accessibility-Mod-Template/docs/` - Guides, checklists, and API documentation
- `Accessibility-Mod-Template/templates/` - Code templates for common features
- `Accessibility-Mod-Template/scripts/` - PowerShell helper scripts
- `Accessibility-Mod-Template/decompiled/` - Game source code (you add this during setup)
- `Accessibility-Mod-Template/AGENTS.md` - Instructions for Codex integration

## Contributing

This template is designed for blind developers and their AI assistants. Contributions that improve clarity, add useful patterns, or expand documentation are welcome.

## Credits

This template was built with invaluable support from **Jean Stiletto** and **Firefly82**. Thank you so much for contributing your accessibility modding experience, brilliant ideas, your enthusiasm, and patient testing!

Your contributions helped me create a template that actually works.
