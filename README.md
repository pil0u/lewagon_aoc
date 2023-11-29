![Le Wagon x Advent of Code](public/thumbnail.png)

```
Ruby    3.2.2  
Rails   7.1.1
```

Found a bug? Do not hesitate to [open an Issue](/../../issues/new).  
Have a feature request? Let's discuss it [on Slack](slack://user?team=T02NE0241&id=URZ0F4TEF).

## Contribute

If you want to help me fix a bug or implement a new requested feature:
1. Make sure [an Issue exists](/../../issues) for it
2. Ask me questions
3. Fork the project
4. Code the changes on your fork
5. Create a Pull Request here from your fork

### CI with GitHub Action

Upon Pull Requests (open, push), CI scripts are automatically run:
- linters (RuboCop, ERBLint)
- security tools (brakeman, bundler-audit)
- tests

Your PR should pass the linters, the security checks and the tests to be reviewed.

### Run on your machine

1. Run `bin/setup` to install dependencies, create and seed the database
2. Ask me for the credentials key and add it to `config/master.key`, required for Kitt OAuth
3. Create a `.env` root file and add these keys with their [appropriate values](#required-env-variables): `AOC_ROOMS`, `SESSION_COOKIE`
4. Run `bin/dev`

#### Required `ENV` variables

> **Warning**
The `.env` file is used for development purposes only. It is _not_ versioned and never should.

- `AOC_ROOMS` is a comma-separated list of [private leaderboard](https://adventofcode.com/leaderboard/private) IDs that _you belong_ to (e.g. `9999999-a0b1c2d3,7777777-e4f56789`)
- `SESSION_COOKIE` is your own Advent of Code session cookie (valid ~ 1 month). You need to [log in](https://adventofcode.com/auth/login) to the platform, then retrieve the value of the `session` cookie (e.g. `436088a93cbdba07668e76df6d26c0dcb4ef3cbd5728069ffb647678ad38`)

#### Overmind

> **Note**
> Foreman is the default process manager through the `bin/dev` command. Overmind is an optional alternative.

Overmind is a process manager for Procfile-based applications like ours, based on `tmux`. You can install the tool on your machine [following these instructions](https://github.com/DarthSim/overmind#installation).

Add these lines to your local `.env` file:
```zsh
OVERMIND_PORT=3000
OVERMIND_PROCFILE=Procfile.dev
```

Then, instead of the usual `bin/dev`, you have to run `overmind s`.

#### Use SSL

In short: create an SSL certificate for your localhost, store it in your keychain and run the server using that certificate.

```zsh
mkcert localhost
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./localhost.pem
mv localhost* tmp/ # this is the tmp folder in the project root
bin/dev ssl
```

### Launch webapp on local mobile browser

Because the OAuth will not work on your local IP, you have to bypass authentication by **temporarily** adding this line, for example in the `welcome` controller method:
```ruby
sign_in(User.find_by(github_username: "your_username"))
```

Then, find the local IP address of the computer you launch the server from (ex: `192.168.1.14`) and open the app on your mobile browser from that IP (ex: `http://192.168.1.14:3000`)

## Advent of Code API

On `adventofcode.com`, a user can create one (and only one) private leaderboard. Up to 200 users can join it using a unique generated code.

A JSON object containing scores can be fetched from a `GET` request that needs a session cookie to succeed. We store this session cookie in the `SESSION_COOKIE` environment variable (valid ~ 1 month).

We use multiple private leaderboards to run the platform with more than 200 participants. We store their IDs in the `AOC_ROOMS` environment variable, comma-separated. One account joins all of them, and we use this account's `SESSION_COOKIE`.
