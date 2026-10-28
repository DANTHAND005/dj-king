import { test, before, after } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { ref, set, get } from 'firebase/database';

const rules = readFileSync(new URL('../../database.rules.json', import.meta.url), 'utf8');
const song = { videoId: 'dQw4w9WgXcQ', title: 't', channel: 'c', thumbnailUrl: 'https://i.ytimg.com/x.jpg' };
let env;
const db = (uid) => env.authenticatedContext(uid).database();

async function seed(room) {
  await env.withSecurityRulesDisabled((ctx) => set(ref(ctx.database(), 'rooms/ABCD'), {
    hostId: 'host', phase: 'lobby', round: 1, revision: 0, ...room,
  }));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'dj-king-c5353',
    database: { rules, host: '127.0.0.1', port: 9000 },
  });
});
after(() => env.cleanup());

test('locked by default and for signed-out users', async () => {
  await env.clearDatabase();
  await assertFails(get(ref(env.unauthenticatedContext().database(), 'rooms/ABCD')));
  await assertFails(set(ref(db('a'), 'other/x'), 1));
});

test('anyone signed in can create a free room as host only', async () => {
  await env.clearDatabase();
  const room = { hostId: 'host', phase: 'lobby', round: 0, revision: 0 };
  await assertFails(set(ref(db('mallory'), 'rooms/ABCD'), room));
  await assertSucceeds(set(ref(db('host'), 'rooms/ABCD'), room));
  await assertFails(set(ref(db('mallory'), 'rooms/ABCD/phase'), 'voting'));
  await assertFails(set(ref(db('host'), 'rooms/ABCD/phase'), 'bogus'));
});

test('players join only in the lobby, only as themselves', async () => {
  await env.clearDatabase();
  await seed({});
  await assertSucceeds(set(ref(db('p1'), 'rooms/ABCD/players/p1'), { nickname: 'Ann', connected: true }));
  await assertFails(set(ref(db('p1'), 'rooms/ABCD/players/p2'), { nickname: 'Eve', connected: true }));
  await assertFails(set(ref(db('p3'), 'rooms/ABCD/players/p3'), { nickname: '', connected: true }));
  await env.withSecurityRulesDisabled((ctx) => set(ref(ctx.database(), 'rooms/ABCD/phase'), 'genre'));
  await assertFails(set(ref(db('p4'), 'rooms/ABCD/players/p4'), { nickname: 'Late', connected: true }));
  await assertSucceeds(set(ref(db('p1'), 'rooms/ABCD/players/p1/connected'), false));
});

test('only the contestant submits, only during submission, valid videos only', async () => {
  await env.clearDatabase();
  await seed({ phase: 'submission', leftId: 'a', rightId: 'b', deadline: Date.now() + 60000 });
  await assertSucceeds(set(ref(db('a'), 'rounds/ABCD/r1/songs/a'), song));
  await assertFails(set(ref(db('c'), 'rounds/ABCD/r1/songs/c'), song));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r1/songs/a'), song));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r1/songs/b'), { ...song, videoId: 'bad' }));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r1/songs/b'), { ...song, thumbnailUrl: 'http://x' }));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r2/songs/b'), song));
  await env.withSecurityRulesDisabled((ctx) => set(ref(ctx.database(), 'rooms/ABCD/deadline'), Date.now() - 10000));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r1/songs/b'), song));
});

test('votes: voters only, one each, for a contestant, secret from others', async () => {
  await env.clearDatabase();
  await seed({ phase: 'voting', leftId: 'a', rightId: 'b', voters: { v: true }, deadline: Date.now() + 20000 });
  await assertFails(set(ref(db('a'), 'rounds/ABCD/r1/votes/a'), 'a'));
  await assertFails(set(ref(db('v'), 'rounds/ABCD/r1/votes/v'), 'v'));
  await assertSucceeds(set(ref(db('v'), 'rounds/ABCD/r1/votes/v'), 'a'));
  await assertFails(set(ref(db('v'), 'rounds/ABCD/r1/votes/v'), 'b'));
  await assertFails(get(ref(db('b'), 'rounds/ABCD/r1/votes')));
  await assertSucceeds(get(ref(db('host'), 'rounds/ABCD/r1/votes')));
});

test('stop requests come only from the contestant whose song is playing', async () => {
  await env.clearDatabase();
  await seed({ phase: 'songA', leftId: 'a', rightId: 'b' });
  await assertSucceeds(set(ref(db('a'), 'rounds/ABCD/r1/stops/a'), true));
  await assertFails(set(ref(db('b'), 'rounds/ABCD/r1/stops/b'), true));
});
