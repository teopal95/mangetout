package com.mangetout.model;

// An enum is like a list of fixed choices — a field that can only ever be one of these values.
// ItemStatus tells us whether a wishlist item still needs to happen (WANTED)
// or has already been done (DONE).
// Think of it like a checkbox: ☐ WANTED  →  ☑ DONE
public enum ItemStatus {
    WANTED, // The item is on the wishlist but hasn't happened yet
    DONE    // Completed! (recipe cooked, movie watched, place visited, etc.)
}
