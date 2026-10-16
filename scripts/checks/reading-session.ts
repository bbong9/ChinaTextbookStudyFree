import assert from 'node:assert/strict';
import { listenToPassage, followPassage } from '../../apps/web/src/lib/readingSession';
const sentences = [{text:'Hello',audio:'one.mp3'}, {text:'Hi',audio:'two.mp3'}];
async function main() {
  let clock = 0;
  const base = { now:()=>clock, play: async () => 'ended' as const, cancelled: () => false, onSentence: () => {}, wait: async (ms: number) => {clock+=ms;} };
  assert.equal(await listenToPassage(sentences, base), 'completed');
  for (const result of ['error', 'blocked', 'muted', 'missing', 'interrupted'] as const) {
    assert.equal(await listenToPassage(sentences, {...base, play:async () => result}), 'audio-unavailable');
  }
  let starts = 0; let recordings = 0;
  const rec = { ...base, startRecording: async () => {starts++; return true;}, stopRecording:async () => 'blob:recording', onRecording: () => {recordings++;} };
  assert.equal(await followPassage(sentences, rec), 'completed');
  assert.equal(starts,2); assert.equal(recordings,2);
  starts=0; recordings=0;
  assert.equal(await followPassage(sentences, {...rec, startRecording:async () => {starts++; return false;}}), 'recording-unavailable');
  assert.equal(starts,1); assert.equal(recordings,0, 'Permission denial must not produce completion or iterate through every sentence');
  assert.equal(await followPassage(sentences, {...rec, stopRecording:async () => null}), 'recording-unavailable');
  let cancelled=false; let stopped=false;
  assert.equal(await followPassage(sentences, {...rec, cancelled:()=>cancelled, startRecording:async () => {cancelled=true;return true;}, stopRecording:async () => {stopped=true;return null;}}), 'cancelled');
  assert.ok(stopped, 'A recording started after cancellation must immediately stop');
  console.log('Reading completion rejects audio failure, permission denial, empty recording and cancellation.');
}
void main();
