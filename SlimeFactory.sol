 /** 
 * @title MC
 * @dev Implements voting process along with vote delegation
 */
 
import './SafeMath.sol'; 
import './IBEP20.sol';
import './BEP20.sol';
import './SlimeToken.sol';

pragma solidity 0.6.12;


/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}
 

//  referral
interface SlimeFriends {
    function setSlimeFriend(address farmer, address referrer) external;
    function getSlimeFriend(address farmer) external view returns (address);
}

 contract IRewardDistributionRecipient is Ownable {
    address public rewardReferral;
    address public rewardVote;
 

    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
    }
 
}
/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */

// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SlimeFactory   is IRewardDistributionRecipient {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
        uint256 fee;
    }
 
    // The  TOKEN!
    SlimeToken public st;
     
    // Dev address.aqui va el dinero para la falopa del dev
    address public devaddr;
    
    address public divPoolAddress;
    // CAKE tokens created per block.
    uint256 public slimesPerBlock;
    // no se para que pero bueno. ahi está.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when This   mining starts.
    uint256 public startBlock;
    
    uint256 public bonusEndBlock;
     
 
     
    // fee  sum 10% 
    uint256 public divreferralfee = 15; 
    uint256 public divPoolFee = 30;  
    uint256 public divdevfee = 10;  
  
    uint256 public MAX_FEE_ALLOWED = 50;  
    

    uint256 public stakepoolId = 0;  
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
     
    event RewardPaid(address indexed user, uint256 reward);
    event ReferralPaid(address indexed user,address indexed userTo, uint256 reward);
    
    event Burned(uint256 reward);
       
    mapping (uint256 => bool) public enablemethod;   
       
    constructor(
        SlimeToken _st,
        
        address _devaddr,
        address _divPoolAddress, 
        uint256 _slimesPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        st = _st;
      
        devaddr = _devaddr;
        divPoolAddress = _divPoolAddress;
        slimesPerBlock = _slimesPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        
        totalAllocPoint = 0;
        
        enablemethod[0]= false;
        enablemethod[1]= false;
        enablemethod[2]= true;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate, uint256 __lastRewardBlock,uint256 __fee) public onlyOwner {
        
          // if _fee == 10 then 100% of dev and treasury fee is applied, if _fee = 5 then 50% discount, if 0 , no fee
        require(__fee<=10);
        
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = __lastRewardBlock == 0 ? block.number > startBlock ? block.number : startBlock : __lastRewardBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCakePerShare: 0,
            fee:__fee
        }));
        
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner. if update lastrewardblock, need update pools
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate, uint256 __lastRewardBloc,uint256 __fee) public onlyOwner { 
        // if _fee == 10 then 100% of dev and treasury fee is applied, if _fee = 5 then 50% discount, if 0 , no fee
         require(__fee<=10);
         
         if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        if(__lastRewardBloc>0)
            poolInfo[_pid].lastRewardBlock = __lastRewardBloc;
         
            poolInfo[_pid].fee = __fee;
    }
 

   // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending tokens on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(slimesPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(slimesPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
         //st.mint(devaddr, cakeReward.div(5));
         st.mint(address(this), cakeReward); 
         //treasury and dev
         st.mint(divPoolAddress, cakeReward.mul(divPoolFee).div(1000));
         st.mint(devaddr, cakeReward.mul(divdevfee).div(1000));

        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    /** Harvest all pools where user has pending balance at same time!  Be careful of gas spending! **/
    function massHarvest(uint256[] memory idsx) public { 
            require(enablemethod[0]);
            
        uint256 idxlength = idsx.length; 
        address nulladdress = address(0); 
          for (uint256 i = 0; i < idxlength;  i++) {
                 deposit(idsx[i],0,nulladdress);
            }
        
    }
    
      /** Harvest & stake to stakepool all pools where user has pending balance at same time!  Be careful of gas spending! **/
    function massStake(uint256[] memory idsx) public { 
         require(enablemethod[1]);
        uint256 idxlength = idsx.length; 
          for (uint256 i = 0; i < idxlength;  i++) {
                 stakeReward(idsx[i]);
            } 
    }
    
    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount,address referrer) public   {

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        // anti -backdoor 
         require((block.number >= pool.lastRewardBlock || _amount==0) ,"pool didnt start yet");
        
        updatePool(_pid); 
         if (_amount>0 && rewardReferral != address(0) && referrer != address(0)) {
            SlimeFriends(rewardReferral).setSlimeFriend (msg.sender, referrer);
        }
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
               payRefFees(pending);
              safeStransfer(msg.sender, pending);
              emit RewardPaid(msg.sender, pending); 
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
           if(pool.fee > 0){
                // if pool.fee = 10 ==>  35 * 10/10000 = 3,5% fee
                // if pool.fee = 5 ==>  35 * 5/10000 = 1,75 fee
                // if pool.fee = 0 ==>  35 * 0/10000 = 0 fee
                uint256 treasuryfee = _amount.mul(pool.fee).mul(divPoolFee).div(10000);
                uint256 devfee = _amount.mul(pool.fee).mul(divdevfee).div(10000);
 
                 pool.lpToken.safeTransfer(divPoolAddress, treasuryfee);
                 pool.lpToken.safeTransfer(devaddr, devfee);
 
                user.amount = user.amount.add(_amount).sub(treasuryfee).sub(devfee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
         
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // user can choose autoStake reward to stake pool instead just harvest
    function stakeReward(uint256 _pid) public {
        require(enablemethod[2] && _pid!=stakepoolId);
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        
           if (user.amount > 0) {
            PoolInfo storage pool = poolInfo[_pid];   
            
            updatePool(_pid);
            
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                payRefFees(pending);
                 
                safeStransfer(msg.sender, pending);
                emit RewardPaid(msg.sender, pending); 
                
                deposit(stakepoolId,pending,address(0));
                
            }
          user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        }
         
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

      
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
         safeStransfer(msg.sender, pending);
         emit RewardPaid(msg.sender, pending); 
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    function payRefFees( uint256 pending ) internal
    { 
        uint256 toReferral   =pending.mul(divreferralfee).div(1000);// 2% 
   
         address referrer = address(0);
          if (rewardReferral != address(0)) {
                referrer = SlimeFriends(rewardReferral).getSlimeFriend (msg.sender);
               
            }
            
            if (referrer != address(0)) { // send commission to referrer 
               st.mint(referrer, toReferral);
                emit ReferralPaid(msg.sender, referrer,toReferral); 
            } 
  
    
    }
    

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
  
    function changeSlimiesPerBlock(uint256 _slimesPerBlock) public onlyOwner {
        slimesPerBlock = _slimesPerBlock;
    }
 
    function safeStransfer(address _to, uint256 _amount) internal {
        uint256 sbal = st.balanceOf(address(this));
        if (_amount > sbal) {
            st.transfer(_to, sbal);
        } else {
            st.transfer(_to, _amount);
        }
    }
    
    
      function updateFees(uint256 _devFee,uint256 _refFee,uint256 _divPoolFee ) public onlyOwner{

       require(_devFee <= MAX_FEE_ALLOWED && _refFee <= MAX_FEE_ALLOWED &&  _divPoolFee <= MAX_FEE_ALLOWED);
        divdevfee = _devFee; 
        divreferralfee = _refFee;
        divPoolFee = _divPoolFee; 
    }
  
    function setdivPoolAddress(address _divPoolAddress)  public onlyOwner  {
        
        divPoolAddress =_divPoolAddress;
    }
    // Update dev address by the previous dev.
    function devAddress(address _devaddr) public onlyOwner{
        devaddr = _devaddr;
    }
    
    //set what will be the stake pool 
    function setStakePoolId(uint256 _id)  public onlyOwner  {
        stakepoolId =_id;
    }
    
    function enableMethod(uint256 _id,bool enabled) public onlyOwner
    { 
        enablemethod[_id]= enabled;
    }
}