git commits are only allowed if there are no untracked/unstaged changes

git commits are only allowed if meta/lint.sh passes with no findings

build and test validation should use meta/pdpmake.sh instead of raw system
make; meta/lint.sh includes the full pdpmake stage test gate

changes to files under meta/ must keep meta/README.md up to date

changes to files listed in meta/manifest.md must keep the corresponding
meta/replica/ documentation accurate and useful
