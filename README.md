# Year 5 spelling tester. 
## Written in bash with copilot help (not the best at bash sue me)  
## ! Linux Only !
Prerequisites gTTS and mpg123

For debian install with:
```
sudo apt install pipx
pipx install gTTS
sudo apt install mpg123
```
Then go to your preferred install folder and:
```
https://github.com/Layatan/Mina_Spelling_Test && cd Mina_Spelling_Test
chmod +x spelling.sh
```
[optional] For adults use a more mature wordlist:

`curl https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_alpha.txt -o wordlist.txt`

To play just run it:

`./spelling.sh`

or view the help page:

`./spelling.sh --help`
