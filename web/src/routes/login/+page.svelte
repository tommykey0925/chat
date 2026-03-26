<script lang="ts">
	import { goto } from '$app/navigation';
	import { signUp, confirmSignUp, login as cognitoLogin } from '$lib/auth';
	import { setAuth } from '$lib/stores/auth.svelte';

	let mode = $state<'login' | 'signup' | 'confirm'>('login');
	let email = $state('');
	let password = $state('');
	let confirmCode = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleLogin() {
		loading = true;
		error = '';
		try {
			const session = await cognitoLogin(email, password);
			const idToken = session.getIdToken();
			setAuth(
				{ sub: idToken.payload.sub!, email: idToken.payload.email as string },
				session.getAccessToken().getJwtToken()
			);
			goto('/rooms');
		} catch (e) {
			error = e instanceof Error ? e.message : 'ログインに失敗しました';
		} finally {
			loading = false;
		}
	}

	async function handleSignUp() {
		loading = true;
		error = '';
		try {
			await signUp(email, password);
			mode = 'confirm';
		} catch (e) {
			error = e instanceof Error ? e.message : 'サインアップに失敗しました';
		} finally {
			loading = false;
		}
	}

	async function handleConfirm() {
		loading = true;
		error = '';
		try {
			await confirmSignUp(email, confirmCode);
			mode = 'login';
		} catch (e) {
			error = e instanceof Error ? e.message : '認証コードが正しくありません';
		} finally {
			loading = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center px-4">
	<div class="w-full max-w-sm">
		<h1 class="mb-8 text-center text-2xl font-bold">
			<span class="text-emerald-400">#</span> Chat
		</h1>

		{#if mode === 'confirm'}
			<form onsubmit={(e) => { e.preventDefault(); handleConfirm(); }} class="flex flex-col gap-4">
				<p class="text-sm text-zinc-400">メールに届いた認証コードを入力してください</p>
				<input
					type="text"
					bind:value={confirmCode}
					placeholder="認証コード"
					required
					class="rounded-lg border border-zinc-700 bg-zinc-900 px-4 py-3 text-zinc-50 placeholder-zinc-500 focus:border-emerald-500 focus:outline-none"
				/>
				<button
					type="submit"
					disabled={loading}
					class="rounded-lg bg-emerald-600 py-3 font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
				>
					{loading ? '確認中...' : '確認'}
				</button>
			</form>
		{:else}
			<!-- Tab -->
			<div class="mb-6 flex rounded-lg border border-zinc-800 p-1">
				<button
					onclick={() => { mode = 'login'; error = ''; }}
					class="flex-1 rounded-md py-2 text-sm font-medium transition {mode === 'login' ? 'bg-zinc-800 text-zinc-50' : 'text-zinc-500 hover:text-zinc-300'}"
				>
					ログイン
				</button>
				<button
					onclick={() => { mode = 'signup'; error = ''; }}
					class="flex-1 rounded-md py-2 text-sm font-medium transition {mode === 'signup' ? 'bg-zinc-800 text-zinc-50' : 'text-zinc-500 hover:text-zinc-300'}"
				>
					サインアップ
				</button>
			</div>

			<form
				onsubmit={(e) => { e.preventDefault(); mode === 'login' ? handleLogin() : handleSignUp(); }}
				class="flex flex-col gap-4"
			>
				<input
					type="email"
					bind:value={email}
					placeholder="メールアドレス"
					required
					class="rounded-lg border border-zinc-700 bg-zinc-900 px-4 py-3 text-zinc-50 placeholder-zinc-500 focus:border-emerald-500 focus:outline-none"
				/>
				<input
					type="password"
					bind:value={password}
					placeholder="パスワード"
					required
					minlength="8"
					class="rounded-lg border border-zinc-700 bg-zinc-900 px-4 py-3 text-zinc-50 placeholder-zinc-500 focus:border-emerald-500 focus:outline-none"
				/>
				<button
					type="submit"
					disabled={loading}
					class="rounded-lg bg-emerald-600 py-3 font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
				>
					{loading ? '処理中...' : mode === 'login' ? 'ログイン' : 'サインアップ'}
				</button>
			</form>
		{/if}

		{#if error}
			<p class="mt-4 rounded-lg border border-red-800 bg-red-950 px-4 py-3 text-sm text-red-400">{error}</p>
		{/if}
	</div>
</div>
