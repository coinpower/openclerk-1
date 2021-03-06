<?php
$account_data = array('exchange_name' => get_exchange_name('eobot'));
?>

<div class="instructions_add">
<h2>Adding a <?php echo $account_data['exchange_name']; ?> account</h2>

<ol class="steps">
	<li>Log into your <?php echo $account_data['exchange_name']; ?> account
		and visit your <a href="https://www.eobot.com/developers">API page</a>.<br>
		<img src="<?php echo htmlspecialchars(url_for('img/accounts/eobot1.png')); ?>"></li>

	<li>Copy and paste your <i>Account ID</i> into the <a class="wizard_link" href="<?php echo htmlspecialchars(url_for('wizard_accounts_pools')); ?>">"Add new Mining Pool" form</a>, and click "Add account".<br>
		<img src="<?php echo htmlspecialchars(url_for('img/accounts/eobot2.png')); ?>"></li>
</ol>
</div>

<div class="instructions_safe">
<h2>Is it safe to provide <?php echo htmlspecialchars(get_site_config('site_name')); ?> your <?php echo $account_data['exchange_name']; ?> Account ID?</h2>

<ul>
	<li>At the time of writing, your <?php echo $account_data['exchange_name']; ?> Account ID can only be used to retrieve account balances and worker status;
		it should not be possible to perform transactions or change user details using only your Account ID.</li>

	<li>Your <?php echo $account_data['exchange_name']; ?> Account IDs will <i>never</i> be displayed on the <?php echo htmlspecialchars(get_site_config('site_name')); ?>
		site, even if you have logged in.</li>

	<li>At the time of writing, it is not possible to change or reset your <?php echo $account_data['exchange_name']; ?> Account ID.</li>
</ul>
</div>
