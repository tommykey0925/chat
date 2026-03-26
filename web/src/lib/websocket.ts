import { Client, type IMessage } from '@stomp/stompjs';
import { getAuthState } from '$lib/stores/auth.svelte';

let client: Client | null = null;

export function connect(onConnect?: () => void) {
	const auth = getAuthState();
	const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
	const wsUrl = `${protocol}//${window.location.host}/ws`;

	client = new Client({
		brokerURL: wsUrl,
		connectHeaders: {
			Authorization: `Bearer ${auth.token || ''}`
		},
		reconnectDelay: 5000,
		heartbeatIncoming: 10000,
		heartbeatOutgoing: 10000,
		onConnect: () => {
			onConnect?.();
		},
		onStompError: (frame) => {
			console.error('STOMP error:', frame.headers['message']);
		}
	});

	client.activate();
}

export function subscribe(destination: string, callback: (msg: IMessage) => void) {
	if (!client?.connected) return null;
	return client.subscribe(destination, callback);
}

export function send(destination: string, body: object) {
	if (!client?.connected) return;
	client.publish({ destination, body: JSON.stringify(body) });
}

export function disconnect() {
	if (client) {
		client.deactivate();
		client = null;
	}
}

export function isConnected() {
	return client?.connected ?? false;
}
