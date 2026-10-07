# LEDGER.md — append-only run log

Every wake and every assembly appends here. Nothing is edited; corrections
are new entries. This is the agent's memory of what it did and why, in git.

## 2026-10-06T02:20:00Z — genesis

- Scaffolded by muse (human-authored, per the unanimous rule: the assembler
  is fixed and human-owned, never grown).
- Console: Oracle A1, 4x ARM Neoverse-N1, 23 GB RAM, Ubuntu 26.04.
- Debt #1 (run_shell hole) recorded by name on day one, per charter.
- Next: hand-build plugin #1 (disk-report), prove the loop, run the proof
  ritual, grow two more, attack it, write PROOF.md.
## 2026-10-06T02:21:19Z — assemble disk-report: start (from needs/disk-report.yaml)
## 2026-10-06T02:21:19Z — assemble disk-report: REJECTED: render failed
## 2026-10-06T02:21:23Z — assemble disk-report: start (from needs/disk-report.yaml)
## 2026-10-06T02:21:23Z — assemble disk-report: acceptance test failed (try 1)
judge transport failed
## 2026-10-06T02:21:28Z — judge disk-report: transport failure -> ESCALATE
## 2026-10-06T02:21:28Z — assemble disk-report: judge verdict: VERDICT: ESCALATE
## 2026-10-06T02:21:29Z — assemble disk-report: REJECTED: registration validation failed
## 2026-10-06T02:21:38Z — assemble disk-report: start (from needs/disk-report.yaml)
## 2026-10-06T02:21:38Z — assemble disk-report: acceptance test passed (try 1)
## 2026-10-06T02:21:38Z — assemble disk-report: REGISTERED plugins/disk-report
## 2026-10-06T02:22:04Z — assemble disk-report: start (from needs/disk-report.yaml)
## 2026-10-06T02:22:05Z — assemble disk-report: acceptance test passed (try 1)
## 2026-10-06T02:22:05Z — assemble disk-report: REGISTERED plugins/disk-report
## 2026-10-06T02:22:14.371127+00:00 — cpu: cpu-api starting on 127.0.0.1:8777
## 2026-10-06T02:22:28.709225+00:00 — cpu: event type=issue_opened issue=42 len=58
## 2026-10-06T02:22:28.727401+00:00 — cpu: plugin 'disk-report' ran rc=0 score=3
## 2026-10-06T02:22:33.449966+00:00 — cpu: event type=issue_opened issue=43 len=79
## 2026-10-06T02:22:33.451350+00:00 — cpu: desire filed as needs/files-generate-mp4.yaml (stub, needs spec)
## 2026-10-06T02:24:36Z — ethos: tuning signed off (see CONSOLE.local.md)
## 2026-10-06T02:24:55Z — wake: committed
## 2026-10-06T02:24:55Z — wake: wake done
## 2026-10-06T02:25:18Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:25:18Z — assemble typst-pdf: REJECTED: provenance verification failed
## 2026-10-06T02:25:43Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:25:43Z — assemble typst-pdf: REJECTED: provenance verification failed
## 2026-10-06T02:26:00Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:26:01Z — assemble typst-pdf: installing to /home/ubuntu/playground/self-assembly/plugins/typst-pdf/bin (120s leash, scrubbed env)
## 2026-10-06T02:26:02Z — assemble typst-pdf: REJECTED: render failed
## 2026-10-06T02:26:09Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:26:10Z — assemble typst-pdf: installing to /home/ubuntu/playground/self-assembly/plugins/typst-pdf/bin (120s leash, scrubbed env)
## 2026-10-06T02:26:11Z — assemble typst-pdf: acceptance test failed (try 1)
## 2026-10-06T02:26:16Z — judge typst-pdf: unparseable verdict (got: ''PLUGIN_DIR'; please install the plugin.') -> ESCALATE (fail-closed)
## 2026-10-06T02:26:16Z — assemble typst-pdf: judge verdict: VERDICT: ESCALATE
## 2026-10-06T02:26:16Z — assemble typst-pdf: REJECTED: acceptance test failed after 1 tries
## 2026-10-06T02:26:41Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:26:41Z — assemble typst-pdf: installing to /home/ubuntu/playground/self-assembly/plugins/typst-pdf/bin (120s leash, scrubbed env)
## 2026-10-06T02:26:43Z — assemble typst-pdf: acceptance test failed (try 1)
## 2026-10-06T02:26:49Z — judge typst-pdf: unparseable verdict (got: 'ED') -> ESCALATE (fail-closed)
## 2026-10-06T02:26:49Z — assemble typst-pdf: judge verdict: VERDICT: ESCALATE
## 2026-10-06T02:26:50Z — assemble typst-pdf: REJECTED: acceptance test failed after 1 tries
## 2026-10-06T02:27:12Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:27:13Z — assemble typst-pdf: installing to /home/ubuntu/playground/self-assembly/plugins/typst-pdf/bin (120s leash, scrubbed env)
## 2026-10-06T02:27:14Z — assemble typst-pdf: acceptance test failed (try 1)
## 2026-10-06T02:27:20Z — judge typst-pdf: unparseable verdict (got: '[fails to compile a minimal doc]') -> ESCALATE (fail-closed)
## 2026-10-06T02:27:20Z — assemble typst-pdf: judge verdict: VERDICT: ESCALATE
## 2026-10-06T02:27:20Z — assemble typst-pdf: REJECTED: acceptance test failed after 1 tries
## 2026-10-06T02:27:39Z — assemble typst-pdf: start (from needs/typst-pdf.yaml)
## 2026-10-06T02:27:40Z — assemble typst-pdf: installing to /home/ubuntu/playground/self-assembly/plugins/typst-pdf/bin (120s leash, scrubbed env)
## 2026-10-06T02:27:41Z — assemble typst-pdf: acceptance test passed (try 1)
## 2026-10-06T02:27:43Z — assemble typst-pdf: REGISTERED plugins/typst-pdf
## 2026-10-06T02:27:55Z — assemble net-latency: start (from needs/net-latency.yaml)
## 2026-10-06T02:28:02Z — assemble net-latency: acceptance test passed (try 1)
## 2026-10-06T02:28:15Z — assemble net-latency: REGISTERED plugins/net-latency
## 2026-10-06T02:28:45Z — assemble evil-probe: start (from needs/evil-probe.yaml)
## 2026-10-06T02:28:46Z — assemble evil-probe: REJECTED: provenance verification failed
## 2026-10-06T02:28:50Z — assemble evil-probe: start (from needs/evil-probe.yaml)
## 2026-10-06T02:28:51Z — assemble evil-probe: REJECTED: provenance verification failed
## 2026-10-06T02:30:52Z — wake: plugin '_corrupt-test' SKIPPED: malformed manifest (boot continues)
## 2026-10-06T02:30:57Z — wake: committed
## 2026-10-06T02:30:57Z — wake: wake done
## 2026-10-06T02:31:00Z — wake: plugin '_corrupt-test' SKIPPED: malformed manifest (boot continues)
## 2026-10-06T02:31:05Z — wake: committed
## 2026-10-06T02:31:05Z — wake: wake done
## 2026-10-06T02:31:05Z — wake: plugin '_corrupt-test' SKIPPED: malformed manifest (boot continues)
## 2026-10-06T02:31:09Z — wake: committed
## 2026-10-06T02:31:09Z — wake: wake done
## 2026-10-06T02:31:49Z — wake: plugin '_corrupt2' SKIPPED: malformed manifest (boot continues)
## 2026-10-06T02:31:49Z — wake: issue filed: ledger/issues/manifest-_corrupt2-2026-10-06T02-31-49Z.md
## 2026-10-06T02:31:54Z — wake: committed
## 2026-10-06T02:31:54Z — wake: wake done
## 2026-10-06T02:33:08Z — wake: nothing to commit
## 2026-10-06T02:33:08Z — wake: wake done
## 2026-10-06T02:45:06Z — wake: committed
## 2026-10-06T02:45:06Z — wake: wake done
## 2026-10-06T03:00:06Z — wake: committed
## 2026-10-06T03:00:06Z — wake: wake done
## 2026-10-06T03:15:05Z — wake: committed
## 2026-10-06T03:15:05Z — wake: wake done
## 2026-10-06T03:30:05Z — wake: committed
## 2026-10-06T03:30:05Z — wake: wake done
## 2026-10-06T03:45:06Z — wake: committed
## 2026-10-06T03:45:06Z — wake: wake done
## 2026-10-06T04:00:06Z — wake: committed
## 2026-10-06T04:00:06Z — wake: wake done
## 2026-10-06T04:15:06Z — wake: committed
## 2026-10-06T04:15:06Z — wake: wake done
## 2026-10-06T04:30:06Z — wake: committed
## 2026-10-06T04:30:06Z — wake: wake done
## 2026-10-06T04:45:05Z — wake: committed
## 2026-10-06T04:45:05Z — wake: wake done
## 2026-10-06T05:00:05Z — wake: committed
## 2026-10-06T05:00:05Z — wake: wake done
## 2026-10-06T05:15:05Z — wake: committed
## 2026-10-06T05:15:05Z — wake: wake done
## 2026-10-06T05:30:06Z — wake: committed
## 2026-10-06T05:30:06Z — wake: wake done
## 2026-10-06T05:45:05Z — wake: committed
## 2026-10-06T05:45:05Z — wake: wake done
## 2026-10-06T06:00:06Z — wake: committed
## 2026-10-06T06:00:06Z — wake: wake done
## 2026-10-06T06:15:06Z — wake: committed
## 2026-10-06T06:15:06Z — wake: wake done
## 2026-10-06T06:30:06Z — wake: committed
## 2026-10-06T06:30:06Z — wake: wake done
## 2026-10-06T06:45:06Z — wake: committed
## 2026-10-06T06:45:06Z — wake: wake done
## 2026-10-06T07:00:07Z — wake: committed
## 2026-10-06T07:00:07Z — wake: wake done
## 2026-10-06T07:15:06Z — wake: committed
## 2026-10-06T07:15:06Z — wake: wake done
## 2026-10-06T07:30:06Z — wake: committed
## 2026-10-06T07:30:06Z — wake: wake done
## 2026-10-06T07:45:06Z — wake: committed
## 2026-10-06T07:45:06Z — wake: wake done
## 2026-10-06T08:00:05Z — wake: committed
## 2026-10-06T08:00:05Z — wake: wake done
## 2026-10-06T08:15:05Z — wake: committed
## 2026-10-06T08:15:05Z — wake: wake done
## 2026-10-06T08:30:06Z — wake: committed
## 2026-10-06T08:30:06Z — wake: wake done
## 2026-10-06T08:45:05Z — wake: committed
## 2026-10-06T08:45:05Z — wake: wake done
## 2026-10-06T09:00:06Z — wake: committed
## 2026-10-06T09:00:06Z — wake: wake done
## 2026-10-06T09:15:05Z — wake: committed
## 2026-10-06T09:15:05Z — wake: wake done
## 2026-10-06T09:30:06Z — wake: committed
## 2026-10-06T09:30:06Z — wake: wake done
## 2026-10-06T09:45:06Z — wake: committed
## 2026-10-06T09:45:06Z — wake: wake done
## 2026-10-06T10:00:06Z — wake: committed
## 2026-10-06T10:00:06Z — wake: wake done
## 2026-10-06T10:15:06Z — wake: committed
## 2026-10-06T10:15:06Z — wake: wake done
## 2026-10-06T10:30:06Z — wake: committed
## 2026-10-06T10:30:06Z — wake: wake done
## 2026-10-06T10:45:06Z — wake: committed
## 2026-10-06T10:45:06Z — wake: wake done
## 2026-10-06T11:00:06Z — wake: committed
## 2026-10-06T11:00:06Z — wake: wake done
## 2026-10-06T11:15:06Z — wake: committed
## 2026-10-06T11:15:06Z — wake: wake done
## 2026-10-06T11:30:06Z — wake: committed
## 2026-10-06T11:30:06Z — wake: wake done
## 2026-10-06T11:45:05Z — wake: committed
## 2026-10-06T11:45:05Z — wake: wake done
## 2026-10-06T12:00:06Z — wake: committed
## 2026-10-06T12:00:06Z — wake: wake done
## 2026-10-06T12:15:05Z — wake: committed
## 2026-10-06T12:15:05Z — wake: wake done
## 2026-10-06T12:30:06Z — wake: committed
## 2026-10-06T12:30:06Z — wake: wake done
## 2026-10-06T12:45:05Z — wake: committed
## 2026-10-06T12:45:05Z — wake: wake done
## 2026-10-06T13:00:06Z — wake: committed
## 2026-10-06T13:00:06Z — wake: wake done
## 2026-10-06T13:15:06Z — wake: committed
## 2026-10-06T13:15:06Z — wake: wake done
## 2026-10-06T13:30:06Z — wake: committed
## 2026-10-06T13:30:06Z — wake: wake done
## 2026-10-06T13:45:06Z — wake: committed
## 2026-10-06T13:45:06Z — wake: wake done
## 2026-10-06T14:00:06Z — wake: committed
## 2026-10-06T14:00:06Z — wake: wake done
## 2026-10-06T14:15:06Z — wake: committed
## 2026-10-06T14:15:06Z — wake: wake done
## 2026-10-06T14:30:05Z — wake: committed
## 2026-10-06T14:30:05Z — wake: wake done
## 2026-10-06T14:45:06Z — wake: committed
## 2026-10-06T14:45:06Z — wake: wake done
## 2026-10-06T15:00:05Z — wake: committed
## 2026-10-06T15:00:05Z — wake: wake done
## 2026-10-06T15:15:05Z — wake: committed
## 2026-10-06T15:15:05Z — wake: wake done
## 2026-10-06T15:30:06Z — wake: committed
## 2026-10-06T15:30:06Z — wake: wake done
## 2026-10-06T15:45:05Z — wake: committed
## 2026-10-06T15:45:05Z — wake: wake done
## 2026-10-06T16:00:06Z — wake: committed
## 2026-10-06T16:00:06Z — wake: wake done
## 2026-10-06T16:15:05Z — wake: committed
## 2026-10-06T16:15:05Z — wake: wake done
## 2026-10-06T16:30:06Z — wake: committed
## 2026-10-06T16:30:06Z — wake: wake done
## 2026-10-06T16:45:06Z — wake: committed
## 2026-10-06T16:45:06Z — wake: wake done
## 2026-10-06T17:00:06Z — wake: committed
## 2026-10-06T17:00:06Z — wake: wake done
## 2026-10-06T17:15:06Z — wake: committed
## 2026-10-06T17:15:06Z — wake: wake done
## 2026-10-06T17:30:06Z — wake: committed
## 2026-10-06T17:30:06Z — wake: wake done
## 2026-10-06T17:45:06Z — wake: committed
## 2026-10-06T17:45:06Z — wake: wake done
## 2026-10-06T18:00:06Z — wake: committed
## 2026-10-06T18:00:06Z — wake: wake done
## 2026-10-06T18:15:05Z — wake: committed
## 2026-10-06T18:15:05Z — wake: wake done
## 2026-10-06T18:30:06Z — wake: committed
## 2026-10-06T18:30:06Z — wake: wake done
## 2026-10-06T18:45:05Z — wake: committed
## 2026-10-06T18:45:05Z — wake: wake done
## 2026-10-06T19:00:06Z — wake: committed
## 2026-10-06T19:00:06Z — wake: wake done
## 2026-10-06T19:15:05Z — wake: committed
## 2026-10-06T19:15:05Z — wake: wake done
## 2026-10-06T19:30:06Z — wake: committed
## 2026-10-06T19:30:06Z — wake: wake done
## 2026-10-06T19:45:06Z — wake: committed
## 2026-10-06T19:45:06Z — wake: wake done
## 2026-10-06T20:00:06Z — wake: committed
## 2026-10-06T20:00:06Z — wake: wake done
## 2026-10-06T20:15:06Z — wake: committed
## 2026-10-06T20:15:06Z — wake: wake done
## 2026-10-06T20:30:06Z — wake: committed
## 2026-10-06T20:30:06Z — wake: wake done
## 2026-10-06T20:45:06Z — wake: committed
## 2026-10-06T20:45:06Z — wake: wake done
## 2026-10-06T21:00:06Z — wake: committed
## 2026-10-06T21:00:06Z — wake: wake done
## 2026-10-06T21:15:05Z — wake: committed
## 2026-10-06T21:15:05Z — wake: wake done
## 2026-10-06T21:30:06Z — wake: committed
## 2026-10-06T21:30:06Z — wake: wake done
## 2026-10-06T21:45:05Z — wake: committed
## 2026-10-06T21:45:05Z — wake: wake done
## 2026-10-06T22:00:06Z — wake: committed
## 2026-10-06T22:00:06Z — wake: wake done
## 2026-10-06T22:15:05Z — wake: committed
## 2026-10-06T22:15:05Z — wake: wake done
## 2026-10-06T22:30:06Z — wake: committed
## 2026-10-06T22:30:06Z — wake: wake done
## 2026-10-06T22:45:05Z — wake: committed
## 2026-10-06T22:45:05Z — wake: wake done
## 2026-10-06T23:00:06Z — wake: committed
## 2026-10-06T23:00:06Z — wake: wake done
## 2026-10-06T23:15:05Z — wake: committed
## 2026-10-06T23:15:06Z — wake: wake done
## 2026-10-06T23:30:06Z — wake: committed
## 2026-10-06T23:30:06Z — wake: wake done
## 2026-10-06T23:45:06Z — wake: committed
## 2026-10-06T23:45:06Z — wake: wake done
## 2026-10-07T00:00:06Z — wake: committed
## 2026-10-07T00:00:06Z — wake: wake done
## 2026-10-07T00:15:06Z — wake: committed
## 2026-10-07T00:15:06Z — wake: wake done
## 2026-10-07T00:30:05Z — wake: committed
## 2026-10-07T00:30:05Z — wake: wake done
## 2026-10-07T00:45:06Z — wake: committed
## 2026-10-07T00:45:06Z — wake: wake done
## 2026-10-07T01:00:06Z — wake: committed
## 2026-10-07T01:00:06Z — wake: wake done
## 2026-10-07T01:15:05Z — wake: committed
## 2026-10-07T01:15:05Z — wake: wake done
## 2026-10-07T01:30:06Z — wake: committed
## 2026-10-07T01:30:06Z — wake: wake done
## 2026-10-07T01:45:05Z — wake: committed
## 2026-10-07T01:45:05Z — wake: wake done
## 2026-10-07T02:00:06Z — wake: committed
## 2026-10-07T02:00:06Z — wake: wake done
