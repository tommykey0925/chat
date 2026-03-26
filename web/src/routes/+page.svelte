<script lang="ts">
	import { goto } from '$app/navigation';
	import { getAuthState } from '$lib/stores/auth.svelte';

	$effect(() => {
		const auth = getAuthState();
		if (!auth.loading) {
			goto(auth.isAuthenticated ? '/rooms' : '/login');
		}
	});
</script>
