# Wine 11.18 patch set

`0001`–`0031` are the 11.16 set's ElementalWarrior base, carried over
**unchanged**, numbers included. On 11.18 two report *"Reversed (or previously
applied)"* and are skipped by `Build-Wine-11.18.sh`:

- `0001-downgrade-dxcore-to-10_8` -- as on 11.16. Its fuzzed attempt leaves
  10.8's dxcore sources behind, which `0002`/`0006` then patch; Wine's dxcore is
  identical in 11.16 and 11.18, so the result is the same dxcore r3 ships.
- `0004-vkd3d-shader-zero-pad-output-signature` -- upstream: 11.18's bundled
  vkd3d already has all seven hunks.

`0032`–`0049` are the Affinity patch set, in order. Fifteen are byte-identical
to the 11.16 set; three were ported:

| | |
|---|---|
| `0033` widl | Was "three fixes". The methodimpl table fix is upstream as 8b963e98; the other two remain |
| `0035` widl | Upstream 09eba117 moved the assembly name into `struct winmd`; same fix there |
| `0036` widl | The same commit moved the import list into `struct winmd`; same walk-up there |

`0032` must not ship without `0035`: with the assembly name still set to the
output path, implementing `RoResolveNamespace` makes the CLR fail later and
harder than leaving it stubbed.

Verified against a pristine `wine-11.18.tar.xz` (2026-10-01): `0032`–`0049`
apply in order with no fuzz.
