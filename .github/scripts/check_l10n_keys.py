#!/usr/bin/env python3
"""Localization key audit for TinyRecorder.

Usage: python3 -I l10n_scan.py <repo> [--json out.json]

A = keys used by Swift code (".local", "(...).local", LocalizedStringKey call sites,
    createAlert(title:/message:/button1:/button2:) and other labelled args that are
    localized by their callee)
B = union of keys in zh-Hans / zh-Hant / it Localizable.strings
C = union of keys in every <lang>.lproj/InfoPlist.strings
Prints counts per language and every difference. Exit code 1 if any difference.
"""
import json, os, re, sys

LANGS = ["en", "zh-Hans", "zh-Hant", "it", "ja", "de", "es"]

# ---------- .strings parsing ----------
def read_text(path):
    raw = open(path, "rb").read()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    if len(raw) > 1 and raw[1:2] == b"\x00":
        return raw.decode("utf-16-le")
    return raw.decode("utf-8")

def unescape_strings(s):
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            if n == "n": out.append("\n"); i += 2; continue
            if n == "t": out.append("\t"); i += 2; continue
            if n == "r": out.append("\r"); i += 2; continue
            if n in "\"\\'": out.append(n); i += 2; continue
            if n in "Uu" and re.match(r"[0-9a-fA-F]{4}", s[i + 2:i + 6]):
                out.append(chr(int(s[i + 2:i + 6], 16))); i += 6; continue
            out.append(n); i += 2; continue
        out.append(c); i += 1
    return "".join(out)

def parse_strings(path):
    """Returns (ordered list of (key, value), list of duplicate keys)."""
    t = read_text(path)
    pairs, i, n = [], 0, len(t)
    def skip_ws_comments(i):
        while i < n:
            if t[i].isspace(): i += 1
            elif t.startswith("//", i): i = t.find("\n", i); i = n if i < 0 else i
            elif t.startswith("/*", i): j = t.find("*/", i + 2); i = n if j < 0 else j + 2
            else: break
        return i
    def read_quoted(i):
        assert t[i] == '"', (path, i, t[i:i + 40])
        j = i + 1
        while t[j] != '"':
            j += 2 if t[j] == "\\" else 1
        return t[i + 1:j], j + 1
    while True:
        i = skip_ws_comments(i)
        if i >= n: break
        k, i = read_quoted(i)
        i = skip_ws_comments(i); assert t[i] == "=", (path, t[i:i + 40]); i += 1
        i = skip_ws_comments(i)
        v, i = read_quoted(i)
        i = skip_ws_comments(i); assert t[i] == ";", (path, t[i:i + 40]); i += 1
        pairs.append((unescape_strings(k), unescape_strings(v)))
    seen, dups = set(), []
    for k, _ in pairs:
        if k in seen: dups.append(k)
        seen.add(k)
    return pairs, dups

# ---------- Swift scanning ----------
CALLS = ["Text(", "Button(", "Label(", "Toggle(", "SToggle(", "SPicker(", "SSteper(", "SSlider(",
         "Picker(", "Section(", ".navigationTitle(", ".alert(", ".help(", "Menu(", "TextField(",
         "SecureField(", "Link(", "ColorPicker(", "MatrixColorSelector(", ".confirmationDialog(",
         "KeyboardShortcuts.Recorder(", "SInfoButton(", "Alert(", "LocalizedStringKey("]
LABELS = ["label:", "tips:", "title:", "message:", "button1:", "button2:"]
INDIRECT = ("abortRecording(reason:", "RecordingError(")

def swift_literals(src):
    """Yields (start, end, raw_content, has_interpolation) for each string literal
    outside comments. Handles nested interpolation \\( ... "..." ... )."""
    i, n = 0, len(src)
    while i < n:
        if src.startswith("//", i):
            i = src.find("\n", i); i = n if i < 0 else i; continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2); i = n if j < 0 else j + 2; continue
        if src.startswith('"""', i):
            j = src.find('"""', i + 3); i = n if j < 0 else j + 3; continue
        if src[i] == '"':
            j, interp = i + 1, False
            while j < n and src[j] != '"':
                if src[j] == "\\" and src[j + 1] == "(":
                    interp, depth, j = True, 1, j + 2
                    while depth:
                        if src[j] == "(": depth += 1
                        elif src[j] == ")": depth -= 1
                        elif src[j] == '"':
                            j += 1
                            while src[j] != '"': j += 2 if src[j] == "\\" else 1
                        j += 1
                    continue
                j += 2 if src[j] == "\\" else 1
            yield i, j + 1, src[i + 1:j], interp
            i = j + 1; continue
        i += 1

def unescape_swift(s):
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return unescape_strings(s)

def closing_paren_followed_by_local(src, pos):
    """True if the literal at pos sits inside (...) that is directly followed by .local"""
    depth, i = 0, pos
    while i > 0:
        i -= 1
        c = src[i]
        if c == ")": depth += 1
        elif c == "(":
            if depth == 0: break
            depth -= 1
        elif c in ";{}" and depth == 0: return False
        if pos - i > 600: return False
    else:
        return False
    depth, j = 0, i
    while j < len(src):
        c = src[j]
        if c == "(": depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0: return src.startswith(".local", j + 1)
        elif c == '"':
            j += 1
            while src[j] != '"': j += 2 if src[j] == "\\" else 1
        j += 1
    return False

# LocalizedStringKey turns "\\(x)" into a format specifier chosen by the argument type
# (%@ String, %lld Int) and a literal % into %%. Types verified in the source.
INTERP_KEYS = {
    ' \\(highRes == 2 ? areaWidth * scale : areaWidth) x \\(highRes == 2 ? areaHeight * scale : areaHeight)': ' %lld x %lld',
    'Please run this command in Terminal instead:\\ntccutil reset ScreenCapture \\(Bundle.main.bundleIdentifier ?? "com.33to9.TinyRecorder")': 'Please run this command in Terminal instead:\ntccutil reset ScreenCapture %@',
    'TinyRecorder v\\(appVersion)': 'TinyRecorder v%@',
    '\\(Int(audioPlayerManager.micVol * 100))%': '%lld%%',
    '\\(Int(audioPlayerManager.sysVol * 100))%': '%lld%%',
    '\\(app) - \\(title)': '%@ - %@',
    '\\(countdownValue)': '%lld',
    '\\(frameRate) FPS': '%lld FPS',
    '\\(s.rawValue + 1)': '%lld',
}

CALL_NAMES = tuple(c[:-1] for c in CALLS)

def first_arg_of_call(src, pos):
    """True if the literal at pos is (part of) the first argument of one of CALLS, e.g. the
    branches of Button(flag ? "A" : "B")."""
    depth, i = 0, pos
    while i > 0:
        i -= 1
        c = src[i]
        if c == ")": depth += 1
        elif c == "(":
            if depth == 0: break
            depth -= 1
        elif c == "," and depth == 0: return False
        elif c in ";{}\n" and depth == 0: return False
    else:
        return False
    head = src[max(0, i - 40):i]
    return head.endswith(CALL_NAMES)

def scan_code(root):
    keys, interpolated, where = {}, {}, {}
    for d, _, files in os.walk(os.path.join(root, "TinyRecorder")):
        for f in files:
            if not f.endswith(".swift"): continue
            p = os.path.join(d, f)
            src = open(p, encoding="utf-8").read()
            for s, e, raw, interp in swift_literals(src):
                if raw == "": continue
                before = src[max(0, s - 40):s].rstrip()
                # Failure reasons reach createAlert(message:), which looks them up with .local.
                # Interpolated ones can never match a key, so they are not counted.
                if before.endswith(INDIRECT):
                    if not interp:
                        line = src.count("\n", 0, s) + 1
                        keys.setdefault(unescape_swift(raw), []).append(os.path.relpath(p, root) + ":%d" % line)
                    continue
                localized = (src.startswith(".local", e)
                             or any(before.endswith(c) for c in CALLS)
                             or any(before.endswith(l) for l in LABELS)
                             or closing_paren_followed_by_local(src, s)
                             or first_arg_of_call(src, s))
                if not localized: continue
                if "verbatim:" in before[-12:]: continue
                if re.search(r"(DispatchQueue|OSLog|Logger)\(\s*label:$", before): continue
                line = src.count("\n", 0, s) + 1
                rel = os.path.relpath(p, root) + ":%d" % line
                if interp:
                    interpolated.setdefault(raw, []).append(rel)
                    if raw in INTERP_KEYS:
                        keys.setdefault(INTERP_KEYS[raw], []).append(rel)
                else:
                    k = unescape_swift(raw)
                    keys.setdefault(k, []).append(rel)
    return keys, interpolated

# ---------- report ----------
def main():
    root = sys.argv[1]
    lp = lambda l, f: os.path.join(root, "TinyRecorder", l + ".lproj", f)
    loc, info, problems = {}, {}, []
    for l in LANGS:
        pairs, dups = parse_strings(lp(l, "Localizable.strings"))
        loc[l] = dict(pairs)
        if dups: problems.append("%s Localizable duplicates: %s" % (l, dups))
        empty = [k for k, v in pairs if v == "" and l != "en"]
        if empty: problems.append("%s Localizable empty values: %s" % (l, empty))
        if os.path.exists(lp(l, "InfoPlist.strings")):
            ip, d2 = parse_strings(lp(l, "InfoPlist.strings"))
            info[l] = dict(ip)
            if d2: problems.append("%s InfoPlist duplicates: %s" % (l, d2))
        else:
            problems.append("%s has no InfoPlist.strings" % l)
    A, interp = scan_code(root)
    B = set().union(*(set(loc[l]) for l in ["zh-Hans", "zh-Hant", "it"]))
    C = set().union(*(set(v) for v in info.values()))
    auth = set(A) | B
    print("== counts")
    print("code keys (A): %d   translated union (B): %d   authoritative A∪B: %d   InfoPlist union (C): %d"
          % (len(A), len(B), len(auth), len(C)))
    for l in LANGS:
        print("  %-8s Localizable %4d   InfoPlist %d" % (l, len(loc[l]), len(info.get(l, {}))))
    print("== Localizable: missing per language (vs A∪B)")
    for l in LANGS:
        miss = sorted(auth - set(loc[l]))
        extra = sorted(set(loc[l]) - auth)
        print("  %-8s missing %d, extra %d" % (l, len(miss), len(extra)))
        for k in miss: print("     - %r" % k); problems.append("%s missing %r" % (l, k))
        for k in extra: print("     + %r" % k); problems.append("%s extra %r" % (l, k))
    print("== code keys missing in ALL languages")
    allmiss = sorted(k for k in A if not any(k in loc[l] for l in LANGS))
    for k in allmiss: print("     %r  (%s)" % (k, A[k][0]))
    print("== translated keys not referenced by code (dead-key candidates)")
    dead = sorted(B - set(A))
    for k in dead: print("     %r" % k)
    print("== interpolated literals in localized contexts (key depends on argument types)")
    for k, w in sorted(interp.items()):
        mapped = INTERP_KEYS.get(k)
        print("     %r -> %r  (%s)" % (k, mapped, w[0]))
        if mapped is None: problems.append("unmapped interpolated key %r" % k)
    print("== InfoPlist: missing per language (vs C)")
    for l in LANGS:
        miss = sorted(C - set(info.get(l, {})))
        print("  %-8s missing %d" % (l, len(miss)))
        for k in miss: print("     - %r" % k); problems.append("%s InfoPlist missing %r" % (l, k))
    print("== format specifiers that differ from the key")
    spec = re.compile(r"%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?(?:ll|l|h)?[@dDiuUxXoOfeEgGcCsSpaA%]")
    norm = lambda x: sorted(m.group(0).replace("$", "") for m in spec.finditer(x))
    for l in LANGS:
        for k, v in loc[l].items():
            if l == "en" and v == "": continue
            ks = sorted(re.sub(r"\d+\$", "", m) for m in spec.findall(k))
            vs = sorted(re.sub(r"\d+\$", "", m) for m in spec.findall(v))
            if ks != vs:
                print("  %-8s %r = %r" % (l, k, v)); problems.append("%s specifier mismatch %r" % (l, k))
    if "--json" in sys.argv:
        json.dump({"A": A, "interp": interp, "dead": dead, "allmiss": allmiss},
                  open(sys.argv[sys.argv.index("--json") + 1], "w"), ensure_ascii=False, indent=1)
    print("== RESULT:", "ALIGNED (all differences empty)" if not problems else "%d problems" % len(problems))
    for p in problems:
        if "missing" not in p and "extra" not in p: print("   ", p)
    sys.exit(1 if problems else 0)

if __name__ == "__main__": main()
