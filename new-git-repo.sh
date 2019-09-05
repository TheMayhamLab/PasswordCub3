echo "Enter repo name: "; read NAME

git init
git add .
git commit -m "First commit"
git remote add origin https://github.com/TheMayhamLab/${NAME}.git
git remote -v
git push origin master
git commit
