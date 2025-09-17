package com.nefta.sdk;

public class AdapterListener implements AdapterCallback {

    private final IListener _redirect;

    public AdapterListener(IListener redirect) {
        _redirect = redirect;
    }

    @Override
    public void IOnReady(String s) {

    }

    @Override
    public void IOnInsights(int responseId, int adapterResponseType, String adapterResponse) {
        _redirect.Invoke(responseId, adapterResponseType, adapterResponse);
    }
}
