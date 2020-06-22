# Entropy

Please read this [_great article_](https://blog.cloudflare.com/ensuring-randomness-with-linuxs-random-number-generator/) if you're interested in how entropy works on Linux systems.
It also explains when and how the Linux kernel entropy pool is refilled with entropy.<br/>
One very important part of the article deals with __*math*__, explaining how a 'mix-in' of entropy from a different source can only _add_ bits to the total entropy - thus improve unpredictable randomness which is crucial for safe keys.<br/>
<br/>
If you look at the _offline/entropy.sh_ script of this framework, you will notice the function '_mixor_' that serves the _mix-in_ purpose:<br/>
In case that _you_ decide that, based on your level of trust, the Linux kernel entropy is not safe enough for your needs, then you can mix in additional entropy by providing it as the 2nd parameter to the _offline/entropy_ script.<br/>
Here's an example:<br/>

    ~/bitcoin$  offline/entropy.sh 256 deadbeefffffffffdeadbeef00000000deadbeefffffffffdeadbeef00000000 | offline/createkeys.sh 
    Enter your 32-byte secret as a hex string and press ctrl-d when you're done (ignore this message if you've piped the byte string through STDIN)
    System Entropy: ------------------------------------
    12cfa06d00520efdfbb229addca851df0745c92372d1149f9a6eee81271094a5
    Entropy: -------------------------------------------
    cc621e82ffadf102251f9742dca851dfd9e877cc8d2eeb6044c3506e271094a5
    Private key: ---------------------------------------
    cc621e82ffadf102251f9742dca851dfd9e877cc8d2eeb6044c3506e271094a5
    ... (truncated)

Note how 'Entropy' is xor'd from the system provided entropy _12cfa06d00520efdfbb229addca851df0745c92372d1149f9a6eee81271094a5_ and the user-provided entropy _deadbeefffffffffdeadbeef00000000deadbeefffffffffdeadbeef00000000_<br/>
<br/>


