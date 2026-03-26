<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import '../app.css';
	import { initAuth, getAuthState } from '$lib/stores/auth.svelte';

	let { children } = $props();

	$effect(() => {
		initAuth();
	});
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Chat</title>
	<meta name="viewport" content="width=device-width, initial-scale=1" />
</svelte:head>

{#if getAuthState().loading}
	<div class="flex min-h-screen items-center justify-center bg-zinc-950 text-zinc-50">
		<p class="text-zinc-500">Loading...</p>
	</div>
{:else}
	<div class="min-h-screen bg-zinc-950 text-zinc-50">
		{@render children()}
	</div>
{/if}
