// Generates 6-char human-friendly codes. Allowed: A-Z and 2-9 (avoids
// visually ambiguous I/O/0/1).
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generateRoomCode(length = 6): string {
  let out = '';
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  for (let i = 0; i < length; i++) {
    out += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return out;
}

export function isValidCode(code: string): boolean {
  return /^[A-HJ-KL-NP-Z2-9]{6}$/.test(code);
}