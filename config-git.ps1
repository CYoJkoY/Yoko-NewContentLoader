git config filter.tabspace.clean 'sed "s/\t/    /g"'
git config filter.tabspace.smudge cat
git config commit.cleanup strip