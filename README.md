![deathnote](https://github.com/supernovahs/DeathNote/assets/91280922/69ad8885-de83-4e01-84aa-26e4015829b8)

# Death Note

This protocol is built on top of YearnV3 strategy to protect Eth hodlers , in case of death or critical disabilities. 

## Salient features

- Depositors can invest their Eth using our strategy , which internally deploys the funds to aave v3.
- If depositor does not do any activity for 1 year with our protocol, we assume they are dead , or critically disabled.
- Their funds can now be claimed by their lawyer or family through a receiver address , which the depositor stated when doing the original deposit.

## Testing
You can find the unit tests in [here](https://github.com/supernovahs/DeathNote/blob/master/src/test/Operation.t.sol).
To run tests, 
```
forge test 
```

## Made with ❤️ by 
- [supernovahs.eth](https://www.supernovahs.xyz/)

