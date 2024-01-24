import React from "react";

//avatars sampled from https://boringavatars.com/090f13-171f25-752e2b-c90a02-f2eab7
import a from '/avatar1.png';
import b from '/avatar2.png';
import c from '/avatar3.png';
import d from '/avatar4.png';
import e from '/avatar5.png';
import f from '/avatar6.png';
import g from '/avatar7.png';
import h from '/avatar8.png';


const hashString = (str) => {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0; // Convert to 32bit integer
  }
  return Math.abs(hash);
};

export function Avatar({ player }) {
  // Convert alphanumeric ID to a numeric value
  const numericId = hashString(player.id);

  
  const avatarImages = [a,b,c,d,e,f,g,h];
  const avatarIndex = numericId % avatarImages.length; // Ensure index is within bounds
  const selectedAvatar = avatarImages[avatarIndex];

  return (
    <img
      className="h-full w-full rounded-md shadow bg-white p-1"
      src={selectedAvatar}
      alt="Avatar"
    />
  );
}

