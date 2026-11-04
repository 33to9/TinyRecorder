#!/usr/bin/env python3
"""Grant TCC permissions on a throwaway GitHub-hosted macOS runner so screenshots can be automated.

Never run this on a real Mac. It writes straight into the TCC databases, which only works on
the CI image (it has the access needed to write them).

  sudo python3 grant_permissions.py <bundle-id> <app-executable> <path-client>...
"""
import os
import sqlite3
import sys
import time

bundle_id, app_exec, *path_clients = sys.argv[1:]
now = int(time.time())

# (service, client, client_type) — client_type 0 = bundle id, 1 = absolute path
grants = [
    ("kTCCServiceScreenCapture", bundle_id, 0),
    ("kTCCServiceMicrophone", bundle_id, 0),
    ("kTCCServiceCamera", bundle_id, 0),
    ("kTCCServiceScreenCapture", app_exec, 1),
]
for p in path_clients:  # the tools that drive the UI and capture the screen
    grants += [("kTCCServiceAccessibility", p, 1), ("kTCCServiceScreenCapture", p, 1),
               ("kTCCServicePostEvent", p, 1), ("kTCCServiceAppleEvents", p, 1)]

dbs = ["/Library/Application Support/com.apple.TCC/TCC.db",
       os.path.expanduser(f"~{os.environ.get('SUDO_USER', 'runner')}/Library/Application Support/com.apple.TCC/TCC.db")]

for db in dbs:
    if not os.path.exists(db):
        print(f"skip (missing): {db}")
        continue
    con = sqlite3.connect(db)
    cols = [r[1] for r in con.execute("PRAGMA table_info(access)")]
    defaults = {"auth_value": 2, "auth_reason": 4, "auth_version": 1, "csreq": None, "policy_id": None,
                "indirect_object_identifier_type": 0, "indirect_object_identifier": "UNUSED",
                "indirect_object_code_identity": None, "flags": 0, "last_modified": now,
                "pid": None, "pid_version": None, "boot_uuid": "UNUSED", "last_reminded": 0}
    ok = 0
    for service, client, ctype in grants:
        row = {"service": service, "client": client, "client_type": ctype, **defaults}
        names = [c for c in cols if c in row]
        try:
            con.execute(f"INSERT OR REPLACE INTO access ({','.join(names)}) VALUES ({','.join('?' * len(names))})",
                        [row[c] for c in names])
            ok += 1
        except sqlite3.Error as e:
            print(f"  {db}: {service} {client}: {e}")
    con.commit()
    print(f"{db}: {ok}/{len(grants)} grants written (columns: {len(cols)})")
