import React from "react";


export function Avatar({ id }) {
  return (
    <img
      className="h-full w-full rounded-md shadow bg-white p-1"
      src={`https://api.dicebear.com/9.x/adventurer/svg?seed=${id}`}
      alt="Avatar"
    />
  );
}
