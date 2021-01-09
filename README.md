# keyvalstore
Private lightweight secure key value store

# Usage

```
    $ keyvalstore.sh <key> [<val>]
```

If the <val> arguemnt is not provided then it does a lookup and emits
the value to stdout.  Otherwise, the value is stored with the given
key for later retrieval.

The data is stored as a text file in the user home directory, with hashed
keys and encrypted values.


# Test

```
    $ test/store_retrieve.sh
```


# Recommended configuration

Deploy keyvalstore.sh to /usr/local/bin, or some other directory in the
shell command $PATH.

```
    cp keyvalstore.sh /usr/local/bin/
````

For each key-val dataset create a symlink:

```
    ln -s /usr/local/bin/keyvalstore.sh /usr/local/bin/passwords
```

When a user invokes keyvalstore.sh via this symlink the database text file
created will be written to the user's home dir as: .passwords-kv-db

```
    ln -s /usr/local/bin/keyvalstore.sh /usr/local/bin/birthdays
```

Likewise, invoking keyvalstore.sh via this symlink will generate the database
text file to the user's home dir as: .birthdays-kv-db

# Dependencies

- awk
- sed
- openssl
- md5sum (or md5)
- mktemp
