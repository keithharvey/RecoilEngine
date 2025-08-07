

```prompt

### context
Please use CRLF, it's this project's standard.

@PR engine changes: https://github.com/beyond-all-reason/RecoilEngine/pull/2423/files/ccb3960415b37590441d22e779aaaf0b0e488463#diff-436e94200bb5e3cc08de6632bdef4efe2ec67615816a1e6a3636cda50209f01f

@PR the nascent start of the game changes (these matter considerably less because we're about to change the assumptions a LOT by biting off more in order to simplify): https://github.com/beyond-all-reason/Beyond-All-Reason/pull/5446

The git diff with origin/master and the currently staged diff are available as files in your context.

Ensure the above steps are all completed before proceeding to plan anything. You must consider the full context of all 3 states, both PRs and the git diff before proceeding.

### What do
We want to essentially provide a good team change handler for bar, that orchestrates a bunch of smaller handlers for each specific action in our reason switch statement. The service can also contain the enum and the switch. Should these all be in a subfolder together (team_change?)? And we want to deprecate the fallbacks, then test all 3 variants of the system: (1) updated - engine and game updated, (2) fallbacks - game not updated and engine updated, (3) future - engine deprecation patch applied. Don't generate the deprecation patch yet though, we will do that as a next step. For now we want to focus on (1) but do develop the test grid for all 3 states when you're thinking through a QA table for me.

so I'm trying to ignore this advice (@https://github.com/beyond-all-reason/RecoilEngine/pull/2423/files/ccb3960415b37590441d22e779aaaf0b0e488463#r2230781784) without saying it because I dont think "not touching the engine" is a concern to me. I want to follow CHANGE REASON around and deprecate everything and actually move that concern out of the engine entirely, then write an implementation of that in bar

and more importantly, this comment chain correlates to that discussion, fixing it right entails going all the way, and I think this commentor really nails what that looks like so let's do this: https://github.com/beyond-all-reason/Beyond-All-Reason/pull/5446#discussion_r2257311341
```

```gemini-2.5.-response(for planning cross-check with another model purposes)
Of course. I understand completely. The goal is to treat Lua as the authoritative source for domain logic like transfer reasons, moving this concern out of the engine entirely. We'll deprecate the C++ enum and all its touchpoints, refactoring them to call into Lua, and then implement the full logic in BAR as the prime example.
This is a fantastic approach that aligns with Domain-Driven Design principles, making the engine more of a framework and less of a game-specific monolith.
Here is the plan to make this happen:
Deprecate the C++ Enum: Mark CUnit::ChangeTeamReasonCpp as deprecated to signal its eventual removal.
Create a New Authoritative Lua Enum in BAR: We'll create a new gadget, team_transfer_enum.lua, in BAR that will define the complete and authoritative GG.CHANGETEAM_REASON enum.
Deprecate the Old BAR Enum: The existing enum definition in gadgets.lua will be commented out and marked as deprecated.
Create a Base Lua Handler in the Engine: To ensure backward compatibility for other games, we'll create a new base gadget in Spring, team_transfer_handler.lua, which will provide default handlers for the new Lua call-ins.
Refactor All C++ Enum Usage: Systematically go through every C++ file that uses ChangeTeamReasonCpp and refactor it to call a new, specific SyncedActionFallback event. The original C++ logic will remain as a deprecated fallback.
Implement BAR Handlers: In BAR's new team_transfer_enum.lua, we will implement the logic for all the new SyncedActionFallback events, ensuring BAR's gameplay relies entirely on the new Lua-driven system.
Let's start by deprecating the C++ enum and creating the new authoritative enum in BAR.
```

My response to the above:
```
1. Note that we want to deprecate all the way through the call stack for anything TOUCHING that. We have already begun this work on the C++ side but that's the only code in the diff I'm actually sold on. It's a solid start to deprecating the existing engine usages of reason and ending external exposure to that concept. Please make a comprehensive list (with code links if possible, you can communicate with me through comments if that helps you) 4. let's make each action it's own file with one centralized "handler" for service registration, or something like that. It's ok for the service file to also define the enum. The main gadget should just be switch statement delegator. 5. we already started this, please be careful.  Note the original C++ logic being a fallback is extremely important/must happen in every case
And if you're going to commenting with a note on the enum make it concise. I'm honestly not sure about the comment at all, we're finding every instance. I guess if someone is in another branch maybe it helps someone but they can just review the recently merged PRs or search "change reason".
```
