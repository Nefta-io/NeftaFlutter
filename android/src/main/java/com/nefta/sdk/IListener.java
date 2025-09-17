package com.nefta.sdk;

public interface IListener {
    void Invoke(int responseId, int adapterResponseType, String adapterResponse);
}
