# Codebook: chat messages in the collective inference task (Experiment 2)

## Task context
Four players each see a private sample of critters (rabbits and squirrels) through a "window".
Over repeated rounds, each player chats with one partner at a time for 30 seconds, then reports
an estimate of the overall percentage of rabbits in the population. Messages below are single
chat messages from those exchanges.

## Unit and format
Code each message independently. A message receives one or more codes (multi-label).
Assign every code whose content is present in the message. Order does not matter.

## Codes

**pn — Personal, numerical.** The speaker reports their OWN observations with specific counts
or an explicit count-based ratio of their own sample.
Examples (constructed): "I see 3 rabbits and 1 squirrel", "2 squirrels here", "5:2 rabbits to squirrels in my yard", "only one bunny".

**pb — Personal, belief/qualitative.** The speaker describes their OWN sample or states their OWN
estimate WITHOUT specific counts: qualitative descriptions of their own sample ("mostly rabbits
in mine", "no squirrels"), or their own estimate/percentage/ratio stated as a belief
("I think it's 70% rabbits", "I'm going with 60/40").

**sn — Social, numerical.** Specific counts attributed to OTHER players or to the group as a
whole, including relayed reports ("my last partner saw 4 rabbits"), group totals
("together we have 12 rabbits and 3 squirrels"), or counts attributed to the listener
("you have 4 squirrels").

**sb — Social, belief/qualitative.** Qualitative information or estimates attributed to others
or to the population/group as a whole, without specific counts: relayed qualitative reports
("others said mostly squirrels"), claims about the overall population or the group's consensus
("there are more rabbits than squirrels overall", "everyone is seeing rabbits"), and questions
or statements about others' estimates or the overall ratio.

**q — Question.** The message asks the partner for information (e.g., "how many do you see?",
"what's your percentage?", "you?"). Combine with other codes when the message also contains
information (e.g., "I see 2 rabbits, you?" = pn + q).

**o — Other.** Content with no information about counts or beliefs: greetings alone,
task/interface comments, "unchanged", emotional reactions, off-topic chat. Use o ONLY if no
other code applies.

## Decision rules
1. Counts beat qualitative description: if the speaker gives specific counts for a source, use
   the "n" code for that source; add the "b" code for the same source only if there is also a
   separate qualitative claim or estimate.
2. A message with no speaker attribution but containing counts ("4 rabbits 2 squirrels") is
   about the speaker's own sample (pn), since that is the default in this task.
3. An unattributed population-level claim ("more rabbits than squirrels", "mostly squirrels")
   with no reference to the speaker's own window is sb (claim about the population), not pb.
   If it is clearly about the speaker's own window ("I have mostly rabbits"), it is pb.
4. Percentages or ratios given as the speaker's own estimate of the population ("I think 75%")
   are pb; percentages describing the group's pooled data or consensus ("we're at 75% overall")
   are sb.
5. Empty or unintelligible messages: o.

## Output
One line per message: `uid,codes` where codes is the set of codes joined with `+`
(e.g., `17,pn+q`). Every uid in the batch must receive exactly one line.
