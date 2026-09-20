#!/usr/bin/env python3
"""Ensure Prism/Resources are in the Xcode Resources build phase.

XcodeGen 2.46 resolves `resources:` in the dump but does not emit a
PBXResourcesBuildPhase for this project. Run after `xcodegen generate`:

    xcodegen generate && python3 scripts/ensure-resources.py
"""

from __future__ import annotations

import re
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "Prism.xcodeproj" / "project.pbxproj"


def nid() -> str:
    return uuid.uuid4().hex[:24].upper()


def main() -> None:
    text = PBX.read_text()
    if "Assets.xcassets in Resources" in text and "PBXResourcesBuildPhase" in text:
        print("Resources build phase already present.")
        return

    assets_ref, assets_build = nid(), nid()
    privacy_ref, privacy_build = nid(), nid()
    launch_ref, launch_build = nid(), nid()
    resources_phase, resources_group = nid(), nid()

    build_files = f"""
\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};
\t\t{privacy_build} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {privacy_ref} /* PrivacyInfo.xcprivacy */; }};
\t\t{launch_build} /* LaunchScreen.storyboard in Resources */ = {{isa = PBXBuildFile; fileRef = {launch_ref} /* LaunchScreen.storyboard */; }};
"""
    text = text.replace(
        "/* Begin PBXBuildFile section */\n",
        "/* Begin PBXBuildFile section */\n" + build_files,
    )

    file_refs = f"""
\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{privacy_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; }};
\t\t{launch_ref} /* LaunchScreen.storyboard */ = {{isa = PBXFileReference; lastKnownFileType = file.storyboard; path = LaunchScreen.storyboard; sourceTree = "<group>"; }};
"""
    text = text.replace(
        "/* Begin PBXFileReference section */\n",
        "/* Begin PBXFileReference section */\n" + file_refs,
    )

    resources_section = f"""
/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,
\t\t\t\t{privacy_build} /* PrivacyInfo.xcprivacy in Resources */,
\t\t\t\t{launch_build} /* LaunchScreen.storyboard in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

"""
    text = text.replace(
        "/* Begin PBXSourcesBuildPhase section */",
        resources_section + "/* Begin PBXSourcesBuildPhase section */",
    )

    resources_group_block = f"""
\t\t{resources_group} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{assets_ref} /* Assets.xcassets */,
\t\t\t\t{privacy_ref} /* PrivacyInfo.xcprivacy */,
\t\t\t\t{launch_ref} /* LaunchScreen.storyboard */,
\t\t\t);
\t\t\tpath = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
"""
    text = text.replace(
        "/* Begin PBXGroup section */\n",
        "/* Begin PBXGroup section */\n" + resources_group_block,
    )

    # Attach Resources group under the Prism source group (path = Prism).
    prism_group = re.search(
        r"(/\* Prism \*/ = \{\s*isa = PBXGroup;\s*children = \()([^)]*)(\);.*?path = Prism;)",
        text,
        re.S,
    )
    if not prism_group:
        raise SystemExit("Could not find Prism PBXGroup with path = Prism")
    if resources_group not in prism_group.group(2):
        text = (
            text[: prism_group.start(2)]
            + prism_group.group(2)
            + f"\n\t\t\t\t{resources_group} /* Resources */,"
            + text[prism_group.end(2) :]
        )

    # Attach Resources phase to the app target (has Embed Foundation Extensions).
    target = re.search(
        r"(Build configuration list for PBXNativeTarget \"Prism\" \*/;\s*buildPhases = \()([^)]*)(\);)",
        text,
        re.S,
    )
    if not target:
        raise SystemExit("Could not find Prism native target buildPhases")
    if resources_phase not in target.group(2):
        text = (
            text[: target.start(2)]
            + target.group(2)
            + f"\n\t\t\t\t{resources_phase} /* Resources */,"
            + text[target.end(2) :]
        )

    PBX.write_text(text)
    print(f"Patched {PBX.relative_to(ROOT)} with Assets.xcassets Resources phase.")


if __name__ == "__main__":
    main()
