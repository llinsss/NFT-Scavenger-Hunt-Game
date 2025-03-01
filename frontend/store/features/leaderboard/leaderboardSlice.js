import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
const API_URL = "http://localhost:8000";
// api call
export const fetchLeaderboard = createAsyncThunk(
  "user/leaderboard",
  async (thunkApi) => {
    const response = await fetch(API_URL);
    const data = await response.json();
    return data;
  }
);

const initialState = {
  profile: [],
  loading: false,
  value: 10,
};

const leaderboardSlice = createSlice({
  name: "leaderboard",
  initialState,
  reducers: {
    increment: (state) => {
      state.value++;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(fetchLeaderboard.fulfilled, (state, action) => {
      state.loading = false;
      state.profile.push(...action.payload);
    });

    builder.addCase(fetchLeaderboard.pending, (state, action) => {
      state.loading = true;
    });
  },
});

export const { increment } = leaderboardSlice.actions;
export default leaderboardSlice.reducer;