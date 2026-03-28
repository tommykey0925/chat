<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { getMessages, getRoom, getUploadUrl, getDownloadUrl, leaveRoom, searchMessages, type Message, type Room } from '$lib/api';
	import { getAuthState } from '$lib/stores/auth.svelte';
	import { connect, subscribe, send, disconnect, isConnected } from '$lib/websocket';

	let room = $state<Room | null>(null);
	let messages = $state<Message[]>([]);
	let input = $state('');
	let messagesEnd: HTMLDivElement;
	let fileInput: HTMLInputElement;
	let showSearch = $state(false);
	let searchQuery = $state('');
	let searchResults = $state<Message[]>([]);
	let searching = $state(false);
	let imageUrls = $state<Record<string, string>>({});

	const roomId = $derived(page.params.roomId);
	const auth = getAuthState();

	async function loadRoom() {
		try {
			room = await getRoom(roomId);
			const res = await getMessages(roomId);
			messages = res.content.reverse();
			messages.forEach(resolveImageUrl);
			scrollToBottom();
		} catch {
			goto('/rooms');
		}
	}

	function scrollToBottom() {
		setTimeout(() => messagesEnd?.scrollIntoView({ behavior: 'smooth' }), 50);
	}

	function connectWebSocket() {
		connect(() => {
			subscribe(`/topic/room.${roomId}`, (msg) => {
				const message: Message = JSON.parse(msg.body);
				messages = [...messages, message];
				resolveImageUrl(message);
				scrollToBottom();
			});
		});
	}

	function handleSend() {
		if (!input.trim()) return;
		send(`/app/chat/${roomId}`, { content: input, messageType: 'TEXT' });
		input = '';
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter' && !e.shiftKey) {
			e.preventDefault();
			handleSend();
		}
	}

	async function handleFileUpload() {
		const file = fileInput?.files?.[0];
		if (!file) return;

		try {
			const { uploadUrl, s3Key } = await getUploadUrl(roomId, file.name, file.type);
			await fetch(uploadUrl, { method: 'PUT', body: file, headers: { 'Content-Type': file.type } });
			send(`/app/chat/${roomId}`, {
				content: s3Key,
				messageType: file.type.startsWith('image/') ? 'IMAGE' : 'FILE'
			});
		} catch (e) {
			console.error('Upload failed:', e);
		}
		fileInput.value = '';
	}

	async function handleSearch() {
		if (!searchQuery.trim()) return;
		searching = true;
		try {
			const res = await searchMessages(roomId, searchQuery);
			searchResults = res.content;
		} catch {
			searchResults = [];
		} finally {
			searching = false;
		}
	}

	async function handleLeave() {
		await leaveRoom(roomId);
		goto('/rooms');
	}

	async function resolveImageUrl(msg: Message) {
		if (msg.messageType === 'IMAGE' && !imageUrls[msg.id]) {
			try {
				const { downloadUrl } = await getDownloadUrl(msg.content);
				imageUrls = { ...imageUrls, [msg.id]: downloadUrl };
			} catch {
				// ignore
			}
		}
	}

	function isOwnMessage(msg: Message) {
		return msg.senderId === auth.user?.sub;
	}

	$effect(() => {
		if (auth.isAuthenticated && roomId) {
			loadRoom();
			connectWebSocket();
		}
		return () => disconnect();
	});
</script>

<div class="flex h-screen flex-col">
	<!-- Header -->
	<header class="sticky top-0 z-10 flex items-center justify-between border-b border-zinc-800 bg-zinc-950 px-4 py-3 sm:px-6">
		<div class="flex items-center gap-3">
			<a href="/rooms" class="text-zinc-500 hover:text-zinc-300">&larr;</a>
			<h1 class="font-bold">
				<span class="text-emerald-400">#</span> {room?.name || '...'}
			</h1>
		</div>
		<div class="flex items-center gap-2">
			<button
				onclick={() => { showSearch = !showSearch; searchQuery = ''; searchResults = []; }}
				class="rounded px-3 py-1 text-xs text-zinc-500 hover:bg-zinc-800 hover:text-zinc-300"
			>
				検索
			</button>
			<button
				onclick={handleLeave}
				class="rounded px-3 py-1 text-xs text-zinc-500 hover:bg-red-950 hover:text-red-400"
			>
				退出
			</button>
		</div>
	</header>

	<!-- Search Panel -->
	{#if showSearch}
		<div class="border-b border-zinc-800 bg-zinc-900/50 px-4 py-3 sm:px-6">
			<form onsubmit={(e) => { e.preventDefault(); handleSearch(); }} class="flex gap-2">
				<input
					type="text"
					bind:value={searchQuery}
					placeholder="メッセージを検索..."
					class="flex-1 rounded-lg border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm text-zinc-50 placeholder-zinc-500 focus:border-emerald-500 focus:outline-none"
				/>
				<button
					type="submit"
					disabled={searching || !searchQuery.trim()}
					class="rounded-lg bg-zinc-700 px-4 py-2 text-sm text-zinc-200 hover:bg-zinc-600 disabled:opacity-50"
				>
					{searching ? '検索中...' : '検索'}
				</button>
			</form>
			{#if searchResults.length > 0}
				<div class="mt-3 max-h-48 overflow-y-auto">
					{#each searchResults as result (result.id)}
						<div class="border-b border-zinc-800 py-2 last:border-0">
							<span class="text-xs text-emerald-400">{result.senderName}</span>
							<span class="ml-2 text-xs text-zinc-600">{new Date(result.createdAt).toLocaleString('ja-JP')}</span>
							<p class="mt-1 text-sm text-zinc-300">{result.content}</p>
						</div>
					{/each}
				</div>
			{:else if searchQuery && !searching}
				<p class="mt-2 text-xs text-zinc-500">結果なし</p>
			{/if}
		</div>
	{/if}

	<!-- Messages -->
	<div class="flex-1 overflow-y-auto px-4 py-4 sm:px-6">
		{#if messages.length === 0}
			<p class="text-center text-sm text-zinc-600">メッセージはまだありません</p>
		{/if}
		{#each messages as msg (msg.id)}
			<div class="mb-3 {isOwnMessage(msg) ? 'text-right' : ''}">
				{#if !isOwnMessage(msg)}
					<span class="text-xs text-zinc-500">{msg.senderName}</span>
				{/if}
				<div class="{isOwnMessage(msg)
					? 'ml-auto bg-emerald-900/50 border-emerald-800'
					: 'mr-auto bg-zinc-900/50 border-zinc-800'} inline-block max-w-xs rounded-lg border px-3 py-2 text-left sm:max-w-md">
					{#if msg.messageType === 'SYSTEM'}
						<p class="text-xs italic text-zinc-500">{msg.content}</p>
					{:else if msg.messageType === 'IMAGE'}
						{#if imageUrls[msg.id]}
							<img src={imageUrls[msg.id]} alt="画像" class="max-w-full rounded" loading="lazy" />
						{:else}
							<p class="text-sm text-zinc-500">📷 読み込み中...</p>
						{/if}
					{:else if msg.messageType === 'FILE'}
						<p class="text-sm text-zinc-300">📎 ファイル</p>
					{:else}
						<p class="text-sm text-zinc-200">{msg.content}</p>
					{/if}
				</div>
				<div class="mt-0.5 text-[10px] text-zinc-600">
					{new Date(msg.createdAt).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}
				</div>
			</div>
		{/each}
		<div bind:this={messagesEnd}></div>
	</div>

	<!-- Input -->
	<div class="border-t border-zinc-800 px-4 py-3 sm:px-6">
		<div class="flex items-center gap-2">
			<button
				onclick={() => fileInput.click()}
				class="rounded-lg p-2 text-zinc-500 hover:bg-zinc-800 hover:text-zinc-300"
			>
				📎
			</button>
			<input type="file" bind:this={fileInput} onchange={handleFileUpload} class="hidden" />
			<input
				type="text"
				bind:value={input}
				onkeydown={handleKeydown}
				placeholder="メッセージを入力..."
				class="flex-1 rounded-lg border border-zinc-700 bg-zinc-900 px-4 py-2 text-zinc-50 placeholder-zinc-500 focus:border-emerald-500 focus:outline-none"
			/>
			<button
				onclick={handleSend}
				disabled={!input.trim()}
				class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
			>
				送信
			</button>
		</div>
	</div>
</div>
