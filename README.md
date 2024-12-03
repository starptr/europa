# europa

Full configuration of the Tilderef server.

## Quality of Life Improvements

### Automatic SSH Authentication

You can tell `ssh` to automatically authenticate using a public-private keypair. The way this works is that through another trusted pathway, you tell Tilderef about your public key. Then, when you log in, your local ssh client will use your local private key to prove that you own the private key half of the public-private keypair.

For Tilderef, this is done by:
1. Adding your public key in europa under `keys/<your username>/<your label>.pub`. You can set `<your label>` to be anything you want. I recommend setting the label so that you can recall which local client the key is for in the future.
2. Then in `src/serverref.nix`, under `users.users.<your username>.openssh.authorizedKeys.keyFiles`, add your key file to the list. The key file should be the path to the public key you added in step 1. (See `users.users.starptr` as an example.)
3. Then, ask a root user to push the new changes!

#### Alternate Method

The downside of the above method is you have to wait for a root user to push the new change. If you want to do it yourself, you can also do the following:
1. Using your ssh password, log in to Tilderef.
2. Manually place the public key in your `~/.ssh/authorized_keys` file.

However, this method is flakey because you need your ssh password in the first place. Your ssh password is temporary, so it will likely expire after a few days. So I recommend doing this method when you first get your login, and then using the first method for future keys.