![deathnote](https://github.com/supernovahs/DeathNote/assets/91280922/69ad8885-de83-4e01-84aa-26e4015829b8)

# Death Note

This protocol is built on top of YearnV3 strategy to protect Eth hodlers , in case of death or critical disabilities. 

## Salient features

- Depositors can invest their Eth using our strategy , which internally deploys the funds to aave v3.
- If depositor does not do any activity for 1 year with our protocol, we assume they are dead , or critically disabled.
- Their funds can now be claimed by their lawyer or family through a receiver address , which the depositor stated when doing the original deposit.
- Currently we are using ethereum mainnet forking for testing and POC. 

## Design considerations

Some thoughts of mine:-
- I had this idea when I saw a tweet from [Jai](https://twitter.com/Jai_Bhavnani) bhavnani from [Waymont](https://twitter.com/WaymontCo) in their death inheritance service. Where they assume owner is dead if no interaction with private key is done for 1 year.
- Several design modifications were made by me to support Yearn V3. The design could be much different if we don't use Yearnv3. But in this case, it was a requirement to fit the strategy in the constraints of the EIP.
- We are storing msg.sender in the fallback function to use in our Death Note internally. This means no static call is supported.
- This means more cost , but after transient storage is implemented, this cost will significantly reduce.
- We use the callbacks and checks that the Strategy does , like `availableDepositLimit`, `availableWithdrawLimit` ,`_deployFunds` and `_freeFunds` to store and modify our death note and allow family or lawyer to withdraw .
- Since only `_deployFunds` and `_freeFunds` can change state, all the required work had to be done in them. So other view functions(availableDepositLimit andavailableWithdrawLimit ) are doing sanity checks with our storage.
- Before calling `deposit` or `withdraw` ,the caller has to call a public functionc called `tstorereceiver` to temporarily store receiver address in storage. We understand this can be changed by anyone before the caller calls `deposit` or `withdraw`. Adequate protection is asserted by checking the value in storage with the parameter the user gives in deposit or withdraw function using [deposit](https://github.com/supernovahs/DeathNote/blob/2a7326f7a16674025dcf2f643cb3577223b3daaa/src/Strategy.sol#L135) and [withdraw](https://github.com/supernovahs/DeathNote/blob/2a7326f7a16674025dcf2f643cb3577223b3daaa/src/Strategy.sol#L141) . Hence protecting them. We can also implement a lock for some blocks to also improve this aspect.
- We are depositing WETH into aave v3 and withdrawing them . Currently, the strategy to generate yield is fairly simple. There is definitely scope for improvement. But for the time being, my main focus was logic for main strategy .

## Testing

Set the ETH_RPC_URL and etherscan api keu in the .env file , take a look at example.env

You can find the unit tests in [here](https://github.com/supernovahs/DeathNote/blob/master/src/test/Operation.t.sol).
To run tests, 
```
make test 
```
Note, some default test files are commented as static calls are not supported . They are yet to be modified.
## Future Vision
I believe thia strategy can be deployed on every chain wherever aave v3 supports. After feedback from yearn devs, and more testing , I intend to deploy this strategy on Polygon POS and subsequently on rest of the chains. Have to figure out stuff like performance fee, etc . This is a fairly simple strategy, and I expect users to use this strategy in the future frequently, especially efter transient storage hard fork.

## Architecture

### Depositor's final responsiblities 
![Screenshot 2023-12-18 at 5 59 35 PM](https://github.com/supernovahs/DeathNote/assets/91280922/1d727961-bcb5-48c6-845d-cb311c6795a9)

### Receiver's response after depositor's death

![Screenshot 2023-12-18 at 8 19 41 PM](https://github.com/supernovahs/DeathNote/assets/91280922/9be812e1-63ea-4398-a1ee-96d5cfa3185e)


## Safety
This is experimental software and is provided on an "as is" and "as available" basis. We do not give any warranties and will not be liable for any loss incurred through any use of this codebase. This code is strictly for educational purposes only. Not for production use.

## Made with ❤️ by 
- [supernovahs.eth](https://www.supernovahs.xyz/)

