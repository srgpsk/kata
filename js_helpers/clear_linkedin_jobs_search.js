/*
 * Builds a clean job list by eliminating the crap.
 * No pagination support yet.
 *
 */

/*
 * Map of element selectors to match and the corresponding text
 * that the element should contain, in order to decide if the job card should be hidden.
 */

const jobHidingConditions = new Map([
    [
        // one element -> multiple text matches
        '.job-card-container__footer-item',
        ['Promoted', 'Applied'],
    ],
    [
        // one element -> one text match
        '.job-card-container__footer-item--highlighted',
        'We won',
    ],
]);

(function hidePromoted(conditions) {
    'use strict';

    console.clear();
    console.info('LinkedIn job list clearing started.');

    const $jobList = document.querySelector('.scaffold-layout__list-container');
    const $topScrollTarget = document.querySelector('[data-results-list-top-scroll-sentinel]');
    const isIterable = (v) => !!v?.[Symbol.iterator];
    const isScalar = (v) => v !== Object(v);

    // not a job search page
    if ($jobList === null) {
        console.warn("Can't find a job list. Make sure you're on the LinkedIn job search page.");
        return;
    }

    // go through the list and hide jobs by criteria
    uroboros($jobList.firstElementChild, handleEl);

    async function uroboros(el, handler) {
        if (el === null) {
            console.info('Done. The job list is cleaned.');
            $topScrollTarget.scrollIntoView();
            return;
        }

        handler(el);
        return uroboros(el.nextElementSibling, handler);
    }

    function handleEl(el) {
        if (el.firstElementChild) {
            action(el);
            return;
        }

        el.scrollIntoView();
        setTimeout(() => handleEl(el), 300);
    }

    function action(el) {
        for (let [selector, text] of conditions) {
            if (isScalar(text)) text = [text];

            for (const t of text) {
                if (el.querySelector(selector)?.textContent.trim().includes(t)) {
                    el.style.display = 'none';
                    break;
                }
            }
        }
    }
})(jobHidingConditions);
